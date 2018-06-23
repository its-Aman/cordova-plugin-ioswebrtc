var exec = require('cordova/exec');

// exports.coolMethod = function (arg0, success, error) {
//     exec(success, error, 'IosWebRTC', 'coolMethod', [arg0]);
// };

// exports.printIt = function (arg0, success, error) {
//     exec(success, error, 'IosWebRTC', 'printIt', [arg0]);
// };

function IosWebRTC() {
    console.log("IosWebRTC.js: is created");
}

IosWebRTC.prototype.echo = function (arg0, success, error) {
    exec(success, error, 'IosWebRTC', 'echo', [arg0]);
};

IosWebRTC.prototype.getCallback = function (callback, success, error) {
    IosWebRTC.prototype.callbackResult = callback;
    exec(success, error, "IosWebRTC", 'callback', []);
}

// CALLBACK RESULT//
IosWebRTC.prototype.callbackResult = (payload) => {
    console.log("Received callbackResult", payload);
}

var iosWebRTC = new IosWebRTC();
module.exports = iosWebRTC;