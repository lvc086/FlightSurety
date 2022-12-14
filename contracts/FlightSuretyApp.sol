pragma solidity ^0.4.24;
//pragma solidity ^0.5;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./FlightSuretyData.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner; // Account used to deploy contract
    address dataContractAddress;
    FlightSuretyData dataContract;


    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        // Modify to call data contract's status
        require(isOperational(), "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
     * @dev Modifier that requires that an airline is registered
     */
    modifier requireRegisteredAirline(address airlineAddress) {
        require(dataContract.airlineRegistered(airlineAddress), "Airline is not yet registered");
        _;
    }

    /**
     * @dev Modifier that requires that an airline is unregistered
     */
    modifier requireUnregisteredAirline(address airline) {
        require(!dataContract.airlineRegistered(airline), "Airline is already registered");
        _;
    }

    /**
     * @dev Modifier that ensures that an airline has not already voted
     */
    modifier requireNotAlreadyVoted(address airline, address voter) {
        require(!dataContract.hasAlreadyVoted(airline, voter), "Already voted for this airline");
        _;
    }

    /**
     * @dev Modifier that requires that an airline exists
     */
    modifier requireAirlineExists(address airlineAddress) {
        require(dataContract.airlineFound(airlineAddress), "Airline does not exist");
        _;
    }

    /**
     * @dev Modifier that requires that no flight with the same name exists
     */
    modifier requireUniqueFlight(string memory flightName) {
        require(!dataContract.flightExists(keccak256(abi.encodePacked(flightName))), "Flight already added");
        _;
    }

    /**
     * @dev Modifier that requires that up to one ether is sent
     */
    modifier requireUpToOneEther() {
        require(msg.value > 0 && msg.value <= 10**18, "Must send up to 1 ether");
        _;
    }

    /**
     * @dev Modifier that requires a flight status to be unknown
     */
    modifier requireStatusUnknown(string memory flightName) {
        require(dataContract.latestFlightStatus(keccak256(abi.encodePacked(flightName))) == 0, "Flight status must be unknown");
        _;
    }

    /**
     * @dev Modifier that requires that a flight exists
     */
    modifier requireFlightExists(string memory flightName) {
        require(dataContract.flightExists(keccak256(abi.encodePacked(flightName))), "Flight does not exist");
        _;
    }

    /**
     * @dev Modifier that requires that a flight's airline is participating
     */
    modifier requireFlightAirlineParticipating(string memory flightName) {
        require(dataContract.isFlightAirlineParticipating(keccak256(abi.encodePacked(flightName))), "Flight's airline is not yet participating");
        _;
    }


    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
     * @dev Contract constructor
     *
     */
    constructor(address _dataContract) public {
        contractOwner = msg.sender;
        dataContractAddress = _dataContract;
        dataContract = FlightSuretyData(_dataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns (bool) {
        return dataContract.isOperational(); // Modify to call data contract's status
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/



    /**
     * @dev Modifier that requires that a flight is registered
     */
    function airlineRegistered(address airlineAddress) public view returns(bool) {
        return dataContract.airlineRegistered(airlineAddress);
    }

    /**
     * @dev Funding for Airline
     *
     */
    function addFunding() public payable requireIsOperational requireAirlineExists(msg.sender){
        dataContract.fund.value(msg.value)(msg.sender);
    }

    /**
     * @dev Claim insurance
     *
     */
    function claimInsurance() external payable {
        dataContract.pay(msg.sender);
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy(string memory flightName) public payable requireIsOperational requireStatusUnknown(flightName) requireUpToOneEther requireFlightExists(flightName) requireFlightAirlineParticipating(flightName) {
        dataContract.addInsurance.value(msg.value)(msg.sender, keccak256(abi.encodePacked(flightName)), msg.value);
    }

    /**
     * @dev Add an airline to the registration queue
     *
     */
    function registerAirline(address airlineAddress)
        public
        requireIsOperational  requireRegisteredAirline(msg.sender)
        returns (bool success, uint256 votes)
    {
        dataContract.registerAirline(airlineAddress);
        //success based on if can be registered? first 4?
        return (success, 0);
    }

    /**
     * @dev Function to approve airline
     *
     */
    function approveAirline(address airline) public requireIsOperational requireAirlineExists(airline) requireUnregisteredAirline(airline) requireRegisteredAirline(msg.sender) requireNotAlreadyVoted(airline, msg.sender) {
        dataContract.approveAirline(airline, msg.sender);
    }

    /**
     * @dev Add an airline to the registration queue
     *
     */
    function registerFirstAirline(address airlineAddress)
        public
        requireIsOperational
        requireContractOwner
        returns (bool success, uint256 votes)
    {
        dataContract.registerFirstAirline(airlineAddress);
        //success based on if can be registered? first 4?
        return (success, 0);
    }

    /**
     * @dev Get the latest flight status
     *
     */
    function latestFlightStatus (string memory flightName) public view requireIsOperational requireFlightExists(flightName) returns (uint8){
        return dataContract.latestFlightStatus(keccak256(abi.encodePacked(flightName)));
    }

    /**
     * @dev Register a future flight for insuring.
     *
     */
    function registerFlight(string memory flightName) public requireIsOperational requireUniqueFlight(flightName) requireRegisteredAirline(msg.sender){
        dataContract.registerFlight(keccak256(abi.encodePacked(flightName)), msg.sender);
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(
        address airline,
        //LVC string calldata flight
        string flight,
        uint256 timestamp
    ) public requireIsOperational {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        oracleResponses[key] = ResponseInfo({
            requester: msg.sender,
            isOpen: true
        });

        emit OracleRequest(index, airline, flight, timestamp);
    }

    // region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester; // Account that requested status
        bool isOpen; // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses; // Mapping key is the status code reported
        // This lets us group responses and identify
        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    event OracleReport(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp
    );

    // Register an oracle with the contract
    function registerOracle() external payable requireIsOperational {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

    //LVC function getMyIndexes() external view returns (uint8[3]) {
    function getMyIndexes() external view requireIsOperational returns (uint8[3]) {
        require(
            oracles[msg.sender].isRegistered,
            "Not registered as an oracle"
        );

        return oracles[msg.sender].indexes;
    }


    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(
        uint8 index,
        address airline,
        string memory flight,
        uint256 timestamp,
        uint8 statusCode
    ) public requireFlightExists(flight) {
        require(
            (oracles[msg.sender].indexes[0] == index) ||
                (oracles[msg.sender].indexes[1] == index) ||
                (oracles[msg.sender].indexes[2] == index),
            "Index does not match oracle request"
        );

        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        require(
            oracleResponses[key].isOpen,
            "Flight or timestamp do not match oracle request"
        );

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (
            oracleResponses[key].responses[statusCode].length == MIN_RESPONSES
        ) {
            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            
            dataContract.setFlightStatus(keccak256(abi.encodePacked(flight)), statusCode);
            if(statusCode == STATUS_CODE_LATE_AIRLINE){
                dataContract.creditInsurees(keccak256(abi.encodePacked(flight)));
            }
        }
    }

    function getFlightKey(
        address airline,
        //LVC - string memoryflight
        string flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    //LVC function generateIndexes(address account) internal returns (uint8[3]) {
    function generateIndexes(address account) internal returns (uint8[3]) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - nonce++), account)
                )
            ) % maxValue
        );

        if (nonce > 250) {
            nonce = 0; // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    // endregion
}
