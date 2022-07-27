var FlightSuretyApp = artifacts.require('FlightSuretyApp')
var FlightSuretyData = artifacts.require('FlightSuretyData')
const truffleAssert = require('truffle-assertions');
const web3 = require('web3');

contract('FlightSuretyApp', function(accounts) {

    let airline1 = accounts[2];
    let airline2 = accounts[3];
    let airline3 = accounts[4];
    let airline4 = accounts[5];
    let airline5 = accounts[6];

    // 1st Test
    it("1 - only registered airlines can register the first 4 airlines", async() => {
        let flightSuretyData = await FlightSuretyData.deployed();
        let flightSuretyApp = await FlightSuretyApp.deployed();

        await truffleAssert.reverts(flightSuretyApp.registerAirline(airline2, {from: airline3}), "Airline is not yet registered");
    })

    // 2nd Test
    it("2 - can register the first 4 airlines", async() => {
        let flightSuretyData = await FlightSuretyData.deployed();
        let flightSuretyApp = await FlightSuretyApp.deployed();

        await flightSuretyApp.registerAirline(airline2, {from: airline1});
        await flightSuretyApp.registerAirline(airline3, {from: airline1});
        await flightSuretyApp.registerAirline(airline4, {from: airline1});
        await flightSuretyApp.registerAirline(airline5, {from: airline1});

        assert.equal(true, await flightSuretyData.airlineRegistered(airline1, {from: flightSuretyApp.address}), "Asserting airline 1 is registered")
        assert.equal(true, await flightSuretyData.airlineRegistered(airline2, {from: flightSuretyApp.address}), "Asserting airline 2 is registered")
        assert.equal(true, await flightSuretyData.airlineRegistered(airline3, {from: flightSuretyApp.address}), "Asserting airline 3 is registered")
        assert.equal(true, await flightSuretyData.airlineRegistered(airline4, {from: flightSuretyApp.address}), "Asserting airline 4 is registered")
        assert.equal(false, await flightSuretyData.airlineRegistered(airline5, {from: flightSuretyApp.address}), "Asserting airline 5 is not registered")
    })
    
    // 3rd Test
    it("3 - can register the first 5 airline with 50% votes", async() => {
        let flightSuretyData = await FlightSuretyData.deployed();
        let flightSuretyApp = await FlightSuretyApp.deployed();

        await flightSuretyApp.approveAirline(airline5, {from: airline1});
        assert.equal(false, await flightSuretyData.airlineRegistered(airline5, {from: flightSuretyApp.address}), "Asserting airline 5 is not registered")
        
        await flightSuretyApp.approveAirline(airline5, {from: airline2});
        assert.equal(true, await flightSuretyData.airlineRegistered(airline5, {from: flightSuretyApp.address}), "Asserting airline 5 is registered")
    })

    // 4th Test
    it("4 - only airlines who funded at least 10 eth can participate", async() => {
        let flightSuretyData = await FlightSuretyData.deployed();
        let flightSuretyApp = await FlightSuretyApp.deployed();

        await flightSuretyApp.addFunding({from: airline2, value: web3.utils.toWei('0.5', 'ether')});
        assert.equal(false, await flightSuretyData.isAirlineParticipating(airline2, {from: flightSuretyApp.address}), "Asserting airline 2 is not participating")
        
        await flightSuretyApp.addFunding({from: airline2, value: web3.utils.toWei('9.5', 'ether')});
        assert.equal(true, await flightSuretyData.isAirlineParticipating(airline2, {from: flightSuretyApp.address}), "Asserting airline 2 is participating")
    })
});


// var Test = require('../config/testConfig.js');
// var BigNumber = require('bignumber.js');

// contract('Airline Tests', async (accounts) => {

//   var config;
//   before('setup contract', async () => {
//     config = await Test.Config(accounts);
//     let airline1 = accounts[2];
//     let airline2 = accounts[3];
//     let airline3 = accounts[3];
//     let airline4 = accounts[3];
//   });

//   /****************************************************************************************/
//   /* Operations and Settings                                                              */
//   /****************************************************************************************/

//   it(`can register the first 4 airlines`, async function () {

//     // Get operating status
//     await config.flightSuretyApp.registerAirline(airline1);
//     console.log(await config.flightSuretyData.registeredAirlines.call())

//   });

 
 

// });
