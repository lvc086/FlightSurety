import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace("http", "ws")));
let accounts = [];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);

const INITIAL_ORACLES = 30;
const FIRST_ORACLE_ADDR = 15;
let oracles = {};

const FlightCodes = [
  {
    name: "STATUS_CODE_ON_TIME",
    code: 10
  },
  {
    name: "STATUS_CODE_LATE_AIRLINE",
    code: 20
  },
  {
    name: "STATUS_CODE_LATE_WEATHER",
    code: 30
  },
  {
    name: "STATUS_CODE_LATE_TECHNICAL",
    code: 40
  },
  {
    name: "STATUS_CODE_LATE_OTHER",
    code: 50
  }
]

async function initAccounts(){
  accounts = await web3.eth.getAccounts();
  web3.eth.defaultAccount = accounts[0];
}


setTimeout(async ()=>{
  await initAccounts()
  await handleEventListeners();
  registerOracles();
}, 500)



//function to register oracles
function registerOracles() {
  for (let i = 0; i < INITIAL_ORACLES; i++) {
    let oracleAddress = accounts[FIRST_ORACLE_ADDR + i];
    console.log("Registered oracle "+(i + 1)+ ": " +oracleAddress)
    registerOracle(oracleAddress, i + 1);
  }
}

//function to register one oracle
function registerOracle(oracleAddress, id) {
  oracles[oracleAddress] = {
    id: id
  }
  flightSuretyApp.methods.registerOracle().send({from: oracleAddress, value: web3.utils.toWei("1", "ether"), gas: 6700000}, (error, result)=>{
    if (error) {
      throw error;
    }
    fetchOracleIndexes(oracleAddress);
  });
}

function fetchOracleIndexes(oracleAddress) {
  flightSuretyApp.methods.getMyIndexes().call({from: oracleAddress, gas: 6700000}, (error, result) => {
      if (error) {
        throw error;
      }
      oracles[oracleAddress].indexes = result;
  });
}

async function handleEventListeners() {
  //event listener for OracleRequest
  await flightSuretyApp.events.OracleRequest((error, result)=>{
    result = result.returnValues;

    let event = {
      index: result.index,
      airline: result.airline,
      timestamp: result.timestamp,
      flight: result.flight,
    }

    console.log("Detected OracleRequest Event", event)

    let flight = {
        timestamp: event.timestamp,
        airlineAddress: event.airline,
        flightNumber: event.flight,
    };
 
    submitFlightStatusFromOracles(result.index, flight);
  });

  await flightSuretyApp.events.OracleReport((error, result)=>{
    result = result.returnValues;

    console.log("Detected OracleReport Event", result)

  });

  await flightSuretyApp.events.FlightStatusInfo((error, result)=>{
    result = result.returnValues;

    console.log("Detected FlightStatusInfo Event", result)

  });
}

//function to submit flight 
function submitFlightStatusFromOracles(index, flight) {
  for (let i = 0; i < INITIAL_ORACLES; i++) {
      let oracleAddress = accounts[FIRST_ORACLE_ADDR + i];
      let oracleIndexes = oracles[oracleAddress].indexes;
      if (oracleIndexes.includes(index)) {
          submitFlightStatus(oracleAddress, index, flight);
      }
  }
}
 
//function to submit flight status to contract
function submitFlightStatus(oracleAddress, index, flight) {
  //generate flight status
  let flightStatus = getFlightStatus();
  //submit flight status
  console.log("Oracle", oracleAddress, "submitting", flightStatus, "for", index, flight.flightNumber)

  flightSuretyApp.methods.submitOracleResponse(index, flight.airlineAddress, flight.flightNumber, flight.timestamp, flightStatus).send({from: oracleAddress, gas:6700000}, (error, result) => {
    if (error) {
      console.log("ERROR FROM submitOracleResponse", oracles[oracleAddress], oracleAddress)
      throw error;
    }
  });
  
}

//function to get flight status
function getFlightStatus() {
  let codesLen = FlightCodes.length;
  // return FlightCodes[Math.floor(Math.random() * (codesLen))].code;
  return 20;
}


const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;