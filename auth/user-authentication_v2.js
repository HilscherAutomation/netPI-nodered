var request = require('request');

module.exports = {
   type: "credentials",
   users: function(username) {
       return new Promise(function(resolve) {
           // Do whatever work is needed to check username is a valid
           // user.
           var user = { username: username, permissions: "*" };
           resolve(user);
       });
   },
   authenticate: function(username,password) {
       return new Promise(function(resolve) {
           var auth = 'Basic ' + new Buffer.from(username + ':' + password).toString('base64');
           var url = 'https://127.0.0.1/cockpit/login'
           request.get({
              url : url,
              rejectUnauthorized: false,
              requestCert: true,
              agent: false,
              headers : {
                "Authorization" : auth,
                "cookie" : "cockpit=deleted"
              }
           },
           function (error, response, body) {
            // Do more stuff with 'body' here
              if (!error) {
                  if( response.statusCode === 200 ){ // login successful
                     if ( body !== undefined ) {
                       var bodytoJSON = JSON.parse(body);
                       if( ("csrf-token" in bodytoJSON) == false ) {
                          resolve(null);
                        } else {
                          var user = { username: username, permissions: "*" };
                          resolve(user);
                        }
                     } else {
                       resolve(null);
                     }
                 } else {
                   resolve(null);
                 }
              } else {
                 resolve(null);
              }
           });

       });
   },
   default: function() {
       return new Promise(function(resolve) {
           // Resolve with the user object for the default user.
           // If no default user exists, resolve with null.
           // resolve({anonymous: true, permissions:"read"});
           resolve(null);
       });
   }
}

