"use strict";

var _fabricShim = _interopRequireDefault(require("fabric-shim"));

var _chaincode = _interopRequireDefault(require("./chaincode"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// Testing mockup oblige to start new Chaincode in a separate file
_fabricShim.default.start(new _chaincode.default());
//# sourceMappingURL=index.js.map