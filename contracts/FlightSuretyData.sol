pragma solidity ^0.4.24;
//pragma solidity ^0.5;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false
    address private logicAddress; //logic address

    struct AirlineStatus {
        bool isRegistered;
        bool isParticipating;
        address[] consentedAirlines;
        uint256 consentCount;
        uint256 updatedTimestamp;
    }

    struct Insurance {
        address insuree;
        uint256 amount;
    }

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    mapping(address => uint256) fundings;
    mapping(bytes32 => Insurance[]) insurances;
    mapping(bytes32 => uint256) flight_insurances;
    mapping(address => uint256) withdrawable_balances;
    mapping(address => AirlineStatus) airlines;
    uint256 public registeredAirlines = 0;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor() public {
        contractOwner = msg.sender;
    }

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
        require(operational, "Contract is currently not operational");
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
     * @dev Modifier that requires the logic contract to execute a function
     */
    modifier requireAppContract() {
        require(msg.sender == logicAddress, "Caller is not app contract");
        _;
    }

    /**
     * @dev Modifier that requires the logic contract to execute a function
     */
    modifier requireFirstAirline() {
        require(registeredAirlines == 0, "An airline already exists");
        _;
    }

    /**
     * @dev Modifier that requires that no airline with the same address exists
     */
    modifier requireNewAirline(address airlineAddress) {
        require(!airlineFound(airlineAddress), "Airline already added");
        _;
    }

    /**
     * @dev Modifier that requires an insuree to have a withdrawable balance
     */
    modifier requireWithdrawableBalance(address insuree) {
        require(withdrawable_balances[insuree] > 0, "Nothing to withdraw");
        _;
    }
    
    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**     
     * @dev Checks if an airline already voted for an airline
     *
     */
    function hasAlreadyVoted(address airline, address voter) public view requireIsOperational requireAppContract returns(bool){
        for (uint256 i = 0; i < airlines[airline].consentCount; i = i.add(1)){
            if(airlines[airline].consentedAirlines[i] == voter){
                return true;
            }
        }
        return false;
    }

    /** 
     * @dev Checks if flight name exists
     *
     */
    function flightExists(bytes32 flightName) public view requireIsOperational requireAppContract returns (bool){
        return flights[flightName].updatedTimestamp > 0;
    }

    /**
     * @dev Register a future flight for insuring.
     *
     */
    function registerFlight(bytes32 flightName, address airline) public requireIsOperational requireAppContract{
        flights[flightName] = Flight(true, 0, now, airline);
    }

    /**
     * @dev Set a flight status
     *
     */
    function setFlightStatus(bytes32 flightName, uint8 status) public requireIsOperational requireAppContract{
        flights[flightName].statusCode = status;
    }

    /**
     * @dev Checks if an airline exists
     *
     * @return A bool that shows if an airline exists
     */
    function airlineFound(address airlineAddress) public view requireIsOperational requireAppContract returns (bool) {
        return airlines[airlineAddress].updatedTimestamp > 0 || airlines[airlineAddress].isRegistered ;
    }

    /**
     * @dev Handles airline approval
    *
     */
    function approveAirline(address airline, address voter) public requireIsOperational requireAppContract {
        airlines[airline].consentedAirlines.push(voter);
        airlines[airline].consentCount = airlines[airline].consentCount.add(1);

        if (airlines[airline].consentCount > (registeredAirlines.sub(1)).div(2)){
            airlines[airline].isRegistered = true;
        }
    }

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }


    function getAirline(address airline) public view returns(bool, uint256){
        return (airlines[airline].isRegistered, airlines[airline].updatedTimestamp);
    }

    /**
     * @dev Checks if an airline can be registered
     *
     * @return A bool that shows if an airline can be registered
     */
    function checkAirlineRegistration() private view returns (bool) {
        return registeredAirlines < 4;
    }
    

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Function to see if the airline of a flight is participating
     *
     */
    function isFlightAirlineParticipating(bytes32 flight) public view requireIsOperational requireAppContract returns(bool){
        return airlines[flights[flight].airline].isParticipating;
    }

    /**
     * @dev Function to see if an airline participating
     *
     */
    function isAirlineParticipating(address airline) public view requireIsOperational requireAppContract returns(bool){
        return airlines[airline].isParticipating;
    }

    /**
     * @dev Sets a logic address
     *
     */
    function setLogicAddress(address _logicAddress) public requireIsOperational requireContractOwner {
        logicAddress = _logicAddress;
    }

    /**
     * @dev Add the first airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerFirstAirline(address airlineAddress) public requireIsOperational requireAppContract requireFirstAirline {
        airlines[airlineAddress] = AirlineStatus(true, false, new address[](0), 0, now);
        registeredAirlines++;
    }

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline(address airlineAddress) public requireIsOperational requireAppContract requireNewAirline(airlineAddress) {
        bool canBeRegistered = checkAirlineRegistration();

        airlines[airlineAddress] = AirlineStatus(canBeRegistered, false, new address[](0), 0, now);

        if(canBeRegistered){
            registeredAirlines++;
        }
    }

    /**
     * @dev Checks if an airline exists
     *
     */
    function airlineRegistered(address airlineAddress) public view requireIsOperational requireAppContract returns(bool){
        return airlineFound(airlineAddress) && airlines[airlineAddress].isRegistered;
    }

    /**
     * @dev Gets flight status
     *
     */
    function latestFlightStatus(bytes32 flightName) public view requireIsOperational requireAppContract returns(uint8){
        return flights[flightName].statusCode;
    }

    /**
     * @dev Adds an insurance
     *
     */
    function addInsurance(address insuree, bytes32 flightName, uint256 amount) public payable requireIsOperational requireAppContract {
        insurances[flightName].push(Insurance(insuree, amount));
        flight_insurances[flightName]++;
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees(bytes32 flightName) public requireIsOperational requireAppContract {     
        for (uint256 i=0; i < flight_insurances[flightName]; i = i.add(1)) {
            //get insuree
            address insuree = insurances[flightName][i].insuree;

            if(insurances[flightName][i].amount > 0){
                //set balance as withdrawable
                uint256 claimable = insurances[flightName][i].amount.mul(3).div(2);
                withdrawable_balances[insuree] = withdrawable_balances[insuree].add(claimable);
                // set insurance to 0
                insurances[flightName][i].amount = 0;
            }
        }
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay(address insuree) public requireIsOperational requireAppContract requireWithdrawableBalance(insuree) {
        //reduce balance
        uint256 balance = withdrawable_balances[insuree];
        withdrawable_balances[insuree] = 0;
        //transfer
        insuree.transfer(balance);
    }


    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund(address airline) public payable requireIsOperational requireAppContract {
        fundings[airline] += msg.value;

        //if airline and made deposits of more than 10 ether
        if(airlineFound(airline) && fundings[airline] >= 10 ether){
            airlines[airline].isParticipating = true;
        }
    }

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    function() external payable requireIsOperational {
    }
}
