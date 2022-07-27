
import DOM from './dom';
import Contract from './contract';
import Config from './config.json';
import './flightsurety.css';


(async() => {
    let flightSelect = DOM.elid("flight-number");
    var html = ""
    for (var flight of Config.flights){
        html += '<option value="'+flight.number+'">'+flight.airline+" - "+ flight.airlineName+" - " + flight.number+'</option>';
    }
    flightSelect.innerHTML = html

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
                
            });
        })

        // User-submitted transaction
        DOM.elid('get-status').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.latestFlightStatus(flight, (error, result) => {
                display('Flights', 'Latest Flight Status', [ { label: 'Fetch Flight Status', error: error, value: result} ]);
            })
    
        })

        // User-submitted transaction
        DOM.elid('buy-insurance').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            let to_send_val = DOM.elid('to-send-val').value;
            let to_send_unit = DOM.elid('to-send-unit').value;
            // Write transaction
            contract.buyInsurance(flight, to_send_val, to_send_unit, (error, result) => {
                display('Flights', 'Buy Insurance', [ { label: 'Buy Insurance', error: error, value: result} ]);
            })
    
        })

         // User-submitted transaction
         DOM.elid('withdraw-claim').addEventListener('click', () => {
            // Write transaction
            contract.claimInsurance((error, result) => {
                display('Claim', 'Withdraw Claim', [ { label: 'Withdraw Claim', error: error, value: result} ]);
            })
    
        })

    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







