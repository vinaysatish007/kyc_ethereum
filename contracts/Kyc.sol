pragma solidity ^0.5.1;

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
    }


    // list of all customers
    Customer[] public allCustomers;
    // list of all Banks/Organisations
    Organisation[] public allBanks;
    // list of all requests
    Request[] public allRequests;
    // list of all valid KYCs
    Request[] public validKYCs;



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
        allRequests.length ++;
        allRequests[allRequests.length - 1] = Request(Uname, bankAddress);
    }
    // function to remove request for KYC
    // @Params - Username for the customer
    // @return - This function returns 0 if removal is successful else this return 1 if the Username for the customer is not found
    function removeRequest(string memory Uname) public payable returns (int) {
        for (uint i = 0; i < allRequests.length; ++i) {
            if (stringsEqual(allRequests[i].uname, Uname)) {
                for (uint j = i + 1; j < allRequests.length; ++j) {
                    allRequests[i - 1] = allRequests[i];
                }
                allRequests.length --;
                return 0;
            }
        }
        // throw error if uname not found
        return 1;
    }


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
            "null", 0, 0);
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
        // throw error if uname not found
        return 1;
    }
    // function to return customer profile data
    // @params - Customer username is passed as the Parameters
    // @return - This function return the cutomer data if found, else this function returns an error string.
    function viewCustomer(string memory Uname) public payable returns (string memory) {
        for (uint i = 0; i < allCustomers.length; ++i) {
            if (stringsEqual(allCustomers[i].uname, Uname)) {
                return allCustomers[i].dataHash;
            }
        }
        return "Customer not found in database!";
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
                    if (allCustomers[i].upvotes < 5) {
                        removeKYC(Uname);
                    }
                }
                return 0;
            }
        }
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




    ///////////////////////////////////////////////////////
    // ALL PRIVATE FUNCTIONS //////////////////////////////
    ///////////////////////////////////////////////////////

    // function to add request for KYC
    // @Params - Username for the customer and bankAddress
    // Function is made payable as banks need to provide some currency to start of the KYC process
    function addKYC(string memory Uname, address bankAddress) public payable {
        for (uint i = 0; i < validKYCs.length; ++i) {
            if (stringsEqual(validKYCs[i].uname, Uname) && validKYCs[i].bankAddress ==
                bankAddress) {
                return;
            }
        }
        validKYCs.length ++;
        validKYCs[validKYCs.length - 1] = Request(Uname, bankAddress);
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
}
