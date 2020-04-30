var when = require("when");
var request = require('request');
var fs = require("fs");
var authentication_uri = 'http://127.0.0.1:1778/servicesextern';
var cookieJar = [];
module.exports = {
    type: "credentials",
    users: function (username) {
        
        return when.promise(function (resolve) {
            if (cookieJar === undefined || cookieJar[username] === undefined) {
                resolve(null);
                return;
            }
            var formData = { "username": username, "service": "Node-RED" };
            var contentLength = formData.length;
            request.post({
                url: authentication_uri + '/users',
                form: formData,
                jar: cookieJar,
                headers: [
                {
                    name: 'content-type',
                    value: 'application/x-www-form-urlencoded'
                }
                ],
                json: true,
            }, function (error, response, body) {
                if (!error) {
                    if (body !== undefined && body["status"] === "OK") {
                        if (body["permission"] !== undefined) {
                            var user = { username: username, permissions: body["permission"] };
                            resolve(user);
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
    authenticate: function (username, password) {
        return when.promise(function (resolve) {
            cookieJar[username] = request.jar();
            var formData = { "username": username, "password": password, "service": "Node-RED" };
            var contentLength = formData.length;
            request.post({
                url: authentication_uri + '/servicelogin',
                form: formData,
                jar: cookieJar,
                headers: [
                 {
                     name: 'content-type',
                     value: 'application/x-www-form-urlencoded'
                 }
                ],
                withCredentials: true,
                json: true,
            }, function (error, response, body) {

                if (!error) {
                    if (body !== undefined && body["status"] === "OK") {
                        if (body["permission"] !== undefined) {
                            var user = { username: username, permissions: body["permission"] };
                            resolve(user);
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
    default: function () {
        return when.promise(function (resolve) {
            // Resolve with the user object for the default user.
            // If no default user exists, resolve with null.
            //resolve({ anonymous: true, permissions: "read" });
            resolve(null);
        });
    }
}


