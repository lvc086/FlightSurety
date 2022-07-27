import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        console.log(network)
        let config = Config[network];
        this.flights = Config.flights
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.owner = null;
        this.airlines = [];
        this.passenger;
        this.passengers = [];
        this.statuses = {
            "0": "STATUS_CODE_UNKNOWN",
            "10": "STATUS_CODE_ON_TIME",
            "20": "STATUS_CODE_LATE_AIRLINE",
            "30": "STATUS_CODE_LATE_WEATHER",
            "40": "STATUS_CODE_LATE_TECHNICAL",
            "50": "STATUS_CODE_LATE_OTHER",
        }
        this.initialize(callback);
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
            debugger
           
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

          
            callback();
        });

        
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner, gas:6700000}, (error, result) => {
                callback(error, payload);
            });
    }


    latestFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            flight: flight,
        } 
        self.flightSuretyApp.methods
            .latestFlightStatus(payload.flight).call((error, result) => {
                callback(error, this.statuses[result]);
            });
    }

    buyInsurance(flight, value, unit, callback) {
        let self = this;
        let payload = {
            flight: flight,
        } 

        this.passenger = this.passengers[this.getRandomIndex(this.passengers.length-1)];

        console.log("Sending "+value+" "+unit+" - "+this.web3.utils.toWei(String(value), unit)+" wei")

        this.web3.eth.getBalance(this.passenger).then((result) => {
            console.log("Balance for", this.passenger, "when buying insurance:", result)
        })

        self.flightSuretyApp.methods 
            .buy(payload.flight).send({from:this.passenger, gas:6700000, value: this.web3.utils.toWei(String(value), unit)}, (error, result) => {
                callback(error, flight);
            });
    }

    claimInsurance(callback) {
        let self = this;
        this.web3.eth.getBalance(this.passenger).then((result) => {
            console.log("Balance for", this.passenger, "before claiming:", result)
        })

        self.flightSuretyApp.methods 
            .claimInsurance().send({from:this.passenger, gas:6700000}, (error, result) => {
                callback(error, this.passenger);
                this.web3.eth.getBalance(this.passenger).then((result) => {
                    console.log("Balance for", this.passenger, "after claiming:", result)
                })
            });
    }

    getRandomIndex(max) {
        return Math.floor(Math.random() * max);
    }
}