pragma solidity ^0.5.9;

contract kyc {
    // Struct customer
    // uname - username of the customer
    // dataHash - customer data
    // rating - rating given to customer given based on regularity
    // upvotes - number of upvotes recieved from banks
    // bank - address of bank that validated the customer account
    struct Customer {
        string uname;
        string dataHash;
        uint upvotes;
        address bank;
        string password;
        uint rating;
        uint rating_count;
    }
    // Struct Organisation
    // name - name of the bank/organisation
    // ethAddress - ethereum address of the bank/organisation
    // rating - rating based on number of valid/invalid verified accounts
    // KYC_count - number of KYCs verified by the bank/organisation
    struct Organisation {
        string name;
        address ethAddress;
        uint KYC_count;
        string regNumber;
        uint rating;
        uint rating_count;
    }
    // Struct Organisation
    // uname - username of the customer
    // bankAddress - ethereum address of the bank/organisation
    // Flag determining if a bank is allowed to do the KYC
    struct Request {
        string uname;
        address bankAddress;
        bool isAllowed;
    }


    // list of all customers
    Customer[] public allCustomers;
    // list of all Banks/Organisations
    Organisation[] public allBanks;
    // list of all requests
    Request[] public allRequests;
    // list of all valid KYCs
    Request[] public validKYCs;

    // admin address
    address admin;

    constructor () public {
        admin = msg.sender;
    }



    ///////////////////////////////////////////////////////
    // ALL REQUEST FUNCTIONS //////////////////////////////
    ///////////////////////////////////////////////////////

    // function to add request for KYC
    // @Params - Username for the customer and bankAddress
    // Function is made payable as banks need to provide some currency to start of the KYC process
    function addRequest(string memory Uname, address bankAddress) public payable {
        for (uint i = 0; i < allRequests.length; ++i) {
            if (stringsEqual(allRequests[i].uname, Uname) && allRequests[i].bankAddress ==
                bankAddress) {
                return;
            }
        }
        // update the KYC count of the bank
        for (uint i = 0; i < allBanks.length; ++i) {
            if (allBanks[i].ethAddress == bankAddress) {
                allBanks[i].KYC_count ++;
                break;
            }
        }
        allRequests.length ++;
        allRequests[allRequests.length - 1] = Request(Uname, bankAddress, true);
    }
    // function to remove request for KYC
    // @Params - Username for the customer
    // @return - This function returns 0 if removal is successful else this return 1 if the Username for the customer is not found
    function removeRequest(string memory Uname) public payable returns (int) {
        for (uint i = 0; i < allRequests.length; ++i) {
            if (stringsEqual(allRequests[i].uname, Uname)) {
                // update the KYC count of the bank
                for (uint k = 0; k < allBanks.length; ++k) {
                    if (allBanks[k].ethAddress == allRequests[i].bankAddress) {
                        allBanks[k].KYC_count --;
                        break;
                    }
                }
                for (uint j = i + 1; j < allRequests.length; ++j) {
                    allRequests[i - 1] = allRequests[i];
                }
                allRequests.length --;
                return 0;
            }
        }
        // error if uname not found
        return 1;
    }
    // function to allow bank to do KYC on a customer
    // @Params - Username for the customer, ethAddress of the bank and bool - true if allowed else false
    // @return - This function returns 0 if updation is successful else returns 1 if the request is not found
    function allowBankForKyc(string memory Uname, address bankEthAddress, bool isAllowed) public onlyAdmin payable returns (int) {
        for (uint i = 0; i < allRequests.length; ++i) {
            if (allRequests[i].bankAddress == bankEthAddress && stringsEqual(allRequests[i].uname, Uname)) {
                allRequests[i].isAllowed = isAllowed;
                return 0;
            }
        }
        // error if uname not found
        return 1;
    }
    // function to get all request given by a bank
    // @Params - ethAddress of the bank
    // @return - List of all the requests
    //    function getRequestsOfBank(address memory ethAddress) public view returns (uint256[] memory) {
    //        uint256[] RequestsOfBank;
    //        for (uint i = 0; i < allRequests.length; ++i) {
    //            if (allRequests[i].bankAddress == ethAddress) {
    //                RequestsOfBank.push(allRequests[i].uname);
    //            }
    //        }
    //        return RequestsOfBank;
    //    }


    ///////////////////////////////////////////////////////
    // ALL CUSTOMER FUNCTIONS /////////////////////////////
    ///////////////////////////////////////////////////////


    // function to add a customer profile to the database
    // @params - Username and the hash of data for the customer are passed as parameters
    // returns 0 if successful
    // returns 1 if size limit of the database is reached
    // returns 2 if customer already in network
    function addCustomer(string memory Uname, string memory DataHash) public payable
    returns (int) {
        // throw error if username already in use
        for (uint i = 0; i < allCustomers.length; ++i) {
            if (stringsEqual(allCustomers[i].uname, Uname))
                return 2;
        }
        allCustomers.length ++;
        // throw error if there is overflow in uint
        if (allCustomers.length < 1)
            return 1;
        allCustomers[allCustomers.length - 1] = Customer(Uname, DataHash, 0, msg.sender,
            "", 0, 0);
        return 0;
    }
    // function to remove fraudulent customer profile from the database
    // @params - customer's username is passed as parameter
    // returns 0 if successful
    // returns 1 if customer profile not in database
    function removeCustomer(string memory Uname) public payable returns (int) {
        for (uint i = 0; i < allCustomers.length; ++i) {
            if (stringsEqual(allCustomers[i].uname, Uname)) {
                for (uint j = i + 1; j < allCustomers.length; ++j) {
                    allCustomers[i - 1] = allCustomers[i];
                }
                allCustomers.length --;
                return 0;
            }
        }
        // throw error if uname not found
        return 1;
    }
    // function to modify a customer profile in database
    // @params - Customer username and datahash are passed as Parameters
    // returns 0 if successful
    // returns 1 if customer profile not in database
    function modifyCustomer(string memory Uname, string memory DataHash) public payable
    returns (uint) {
        for (uint i = 0; i < allCustomers.length; ++i) {
            if (stringsEqual(allCustomers[i].uname, Uname)) {
                allCustomers[i].dataHash = DataHash;
                allCustomers[i].bank = msg.sender;
                return 0;
            }
        }
        // error if uname not found
        return 1;
    }
    // function to return customer profile data
    // @params - Customer username is passed as the Parameters and password if required
    // @return - This function return the customer data if found, else this function returns an error string.
    function viewCustomer(string memory Uname, string memory password) public payable returns (string memory) {
        for (uint i = 0; i < allCustomers.length; ++i) {
            if (stringsEqual(allCustomers[i].uname, Uname)) {
                if (stringsEqual(allCustomers[i].password, password)) {
                    return allCustomers[i].dataHash;
                }
                return "password missmatch";
            }
        }
        return "Customer not found in database!";
    }
    // function to return latest bank to update the customer data
    // @params - Customer username is passed as the Parameters
    // @return - This function return the last updated bank ethAddress if found, else this function returns 0 address.
    function viewHistoryForCustomer(string memory Uname) public payable returns (address) {
        for (uint i = 0; i < allCustomers.length; ++i) {
            if (stringsEqual(allCustomers[i].uname, Uname)) {
                return allCustomers[i].bank;
            }
        }
    }
    // function to return customer rating
    // @params - Customer username is passed as the Parameters
    // @return - This function return the customer rating if found, else this function returns 0.
    function viewCustomerRating(string memory Uname) public payable returns (uint) {
        for (uint i = 0; i < allCustomers.length; ++i) {
            if (stringsEqual(allCustomers[i].uname, Uname)) {
                return allCustomers[i].rating;
            }
        }
    }


    // function to modify kyc vote
    // @params - Customer Username and a bool variable - true for upvote and false for down vote is passed to the function
    // @return - This function return 0 if it is successful
    // @return - This function return 1 if Username is not found
    function updateKYCVotes(string memory Uname, bool ifIncrease) public payable returns (uint)
    {
        for (uint i = 0; i < allCustomers.length; ++i) {
            if (stringsEqual(allCustomers[i].uname, Uname)) {
                //update vote
                if (ifIncrease) {
                    allCustomers[i].upvotes ++;
                    if (allCustomers[i].upvotes > 5) {
                        addKYC(Uname, allCustomers[i].bank);
                    }
                }
                else {
                    allCustomers[i].upvotes --;
                    if (allCustomers[i].upvotes <= 5) {
                        removeKYC(Uname);
                    }
                }
                return 0;
            }
        }
        return 1;
    }

    function setPassword(string memory Uname, string memory password) public payable returns (uint) {
        for (uint i = 0; i < allCustomers.length; ++i) {
            if (stringsEqual(allCustomers[i].uname, Uname)) {
                allCustomers[i].password = password;
                return 0;
            }
        }
        // error if uname not found
        return 1;
    }

    // function to modify customer rating
    // @params - Customer Username and a UserRating from 0 to 10
    // @return - This function return 0 if it is successful
    // @return - This function return 1 if Username is not found
    function updateCustomerRating(string memory Uname, uint Urating) public payable returns (uint)
    {
        require(Urating < 11 && Urating >= 0);
        for (uint i = 0; i < allCustomers.length; ++i) {
            if (stringsEqual(allCustomers[i].uname, Uname)) {
                //update rating
                uint current_rating_count = allCustomers[i].rating_count;
                uint current_rating = allCustomers[i].rating;
                allCustomers[i].rating = ((current_rating * current_rating_count) + Urating) / (current_rating_count + 1);

                //update rating count
                allCustomers[i].rating_count = current_rating_count + 1;

                //return success
                return 0;
            }
        }
        //return failure
        return 1;
    }


    ///////////////////////////////////////////////////////
    // ALL BANK FUNCTIONS /////////////////////////////////
    ///////////////////////////////////////////////////////


    // function to add a bank to the database
    // @params - bankName, ethaddress of the Bank and regNumber of the bank are passed as parameters
    // returns 0 if successful
    // returns 1 if size limit of the database is reached
    // returns 2 if bank already in network
    function addBank(string memory bankName, address bankEthAddress, string memory bankRegNumber) public onlyAdmin payable
    returns (int) {
        // throw error if username already in use
        for (uint i = 0; i < allBanks.length; ++i) {
            if (stringsEqual(allBanks[i].name, bankName))
                return 2;
        }
        allBanks.length ++;
        // throw error if there is overflow in uint
        if (allBanks.length < 1)
            return 1;
        allBanks[allBanks.length - 1] = Organisation(bankName, bankEthAddress, 0, bankRegNumber,
            0, 0);
        return 0;
    }
    // function to remove fraudulent bank from the database
    // @params - banks's ethAddress is passed as parameter
    // returns 0 if successful
    // returns 1 if Bank not in database
    function removeBank(address bankEthAddress) public payable onlyAdmin returns (int) {
        for (uint i = 0; i < allBanks.length; ++i) {
            if (allBanks[i].ethAddress == bankEthAddress) {
                for (uint j = i + 1; j < allBanks.length; ++j) {
                    allBanks[i - 1] = allBanks[i];
                }
                allCustomers.length --;
                return 0;
            }
        }
        // throw error if bank ethAddress is not found
        return 1;
    }
    // function to bank name
    // @params - bank ethAddress is passed as the Parameters
    // @return - This function return the bank's name if found, else this function returns error string.
    function getBankName(address bankEthAddress) public payable returns (string memory) {
        for (uint i = 0; i < allBanks.length; ++i) {
            if (allBanks[i].ethAddress == bankEthAddress) {
                return allBanks[i].name;
            }
        }
        return "bank not found";
    }
    // function to return bank ethAddress
    // @params - Bank name is passed as the Parameters
    // @return - This function return the bank's ethAddress if found, else this function returns 0 address.
    function getBankAddress(string memory bankName) public payable returns (address) {
        for (uint i = 0; i < allBanks.length; ++i) {
            if (stringsEqual(allBanks[i].name, bankName)) {
                return allBanks[i].ethAddress;
            }
        }
    }
    // function to return bank rating
    // @params - Bank name is passed as the Parameters
    // @return - This function return the bank's rating if found, else this function returns 0.
    function viewBankRating(string memory bankName) public payable returns (uint) {
        for (uint i = 0; i < allBanks.length; ++i) {
            if (stringsEqual(allBanks[i].name, bankName)) {
                return allBanks[i].rating;
            }
        }
    }
    // function to modify bank rating
    // @params - bank ethAddress and a BankRating from 0 to 10
    // @return - This function return 0 if it is successful
    // @return - This function return 1 if bank is not found
    function updateBankRating(address bankEthAddress, uint bankRating) public payable returns (uint)
    {
        require(bankEthAddress != msg.sender);
        require(bankRating < 11 && bankRating >= 0);
        for (uint i = 0; i < allBanks.length; ++i) {
            if (allBanks[i].ethAddress == bankEthAddress) {
                //update rating
                uint current_rating_count = allBanks[i].rating_count;
                uint current_rating = allBanks[i].rating;
                allBanks[i].rating = ((current_rating * current_rating_count) + bankRating) / (current_rating_count + 1);

                //update rating count
                allBanks[i].rating_count = current_rating_count + 1;

                //return success
                return 0;
            }
        }
        //return failure
        return 1;
    }


    ///////////////////////////////////////////////////////
    // ALL PRIVATE FUNCTIONS //////////////////////////////
    ///////////////////////////////////////////////////////

    // function to add request for KYC only if the bank is allowed
    // @Params - Username for the customer and bankAddress
    // Function is made payable as banks need to provide some currency to start of the KYC process
    function addKYC(string memory Uname, address bankAddress) public payable {
        for (uint i = 0; i < validKYCs.length; ++i) {
            if (stringsEqual(validKYCs[i].uname, Uname) && validKYCs[i].bankAddress ==
                bankAddress) {
                return;
            }
        }
        for (uint i = 0; i < allRequests.length; ++i) {
            if (allRequests[i].bankAddress == bankAddress &&
                stringsEqual(allRequests[i].uname, Uname) &&
                !allRequests[i].isAllowed) {
                return;
            }
        }
        validKYCs.length ++;
        validKYCs[validKYCs.length - 1] = Request(Uname, bankAddress, true);
    }
    // function to remove from valid KYC
    // @Params - Username for the customer
    // @return - This function returns 0 if removal is successful else this return 1 if the Username for the customer is not found
    function removeKYC(string memory Uname) public payable returns (int) {
        for (uint i = 0; i < validKYCs.length; ++i) {
            if (stringsEqual(validKYCs[i].uname, Uname)) {
                for (uint j = i + 1; j < validKYCs.length; ++j) {
                    validKYCs[i - 1] = validKYCs[i];
                }
                validKYCs.length --;
                return 0;
            }
        }
        // throw error if uname not found
        return 1;
    }
    // function to compare two string value
    // This is an internal fucntion to compare string values
    // @Params - String a and String b are passed as Parameters
    // @return - This function returns true if strings are matched and false if the strings are not matching
    function stringsEqual(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i ++)
        {
            if (a[i] != b[i])
                return false;
        }
        return true;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can perform this operation");
        _;
    }
}
