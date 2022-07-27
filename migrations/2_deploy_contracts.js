const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const SafeMath = artifacts.require("../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol");
const fs = require('fs');
const Web3 = require('web3');

module.exports = async (deployer, network, accounts) => {

    await deployer.deploy(SafeMath)
    await deployer.link(SafeMath, FlightSuretyApp)
    await deployer.link(SafeMath, FlightSuretyData )
    console.log(accounts[2])
    let firstAirline = accounts[2];
    let flights = [
        {
            airline: firstAirline,
            airlineName: "AIRLVC",
            number: "FLT1"
        },
        {
            airline: firstAirline,
            airlineName: "AIRLVC",
            number: "FLT2"
        },
        {
            airline: firstAirline,
            airlineName: "AIRLVC",
            number: "FLT3"
        },
        {
            airline: firstAirline,
            airlineName: "AIRLVC",
            number: "FLT4"
        },
        {
            airline: firstAirline,
            airlineName: "AIRLVC",
            number: "FLT5"
        },
        {
            airline: firstAirline,
            airlineName: "AIRLVC",
            number: "FLT6"
        }
        
    ]

    console.log("Airline", firstAirline)
    await deployer.deploy(FlightSuretyData)
    console.log("dataContract address", FlightSuretyData.address)
    let dataContract = await FlightSuretyData.deployed();
    console.log("Deploying appContract")
    console.log(dataContract.address)
    await deployer.deploy(FlightSuretyApp, dataContract.address);
    console.log("Setting Logic Contract")
    await dataContract.setLogicAddress(FlightSuretyApp.address)
    let appContract = await FlightSuretyApp.deployed();
    console.log("Registering first airline")
    await appContract.registerFirstAirline(firstAirline)
    console.log("Adding funding")
    await appContract.addFunding({from: firstAirline, value: (new Web3()).utils.toWei('10', 'ether')})
    console.log("Adding flights")
    for (var flight of flights){
        await appContract.registerFlight(flight.number, {from: flight.airline})
    }

    let config = {
        localhost: {
            url: 'http://localhost:8545',
            dataAddress: FlightSuretyData.address,
            appAddress: FlightSuretyApp.address
        },
        rinkeby: {
            url: 'https://rinkeby.infura.io/v3/12e8d56547c1422aaf3d12f28b43e632',
            dataAddress: FlightSuretyData.address,
            appAddress: FlightSuretyApp.address
        }
    }

    config.flights = flights;
    fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
    fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
}