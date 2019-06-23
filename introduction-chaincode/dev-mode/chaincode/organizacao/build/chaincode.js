"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _fabricShim = _interopRequireDefault(require("fabric-shim"));

var Organizacao = _interopRequireWildcard(require("./controllers/organizacao"));

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = Object.defineProperty && Object.getOwnPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : {}; if (desc.get || desc.set) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

class Chaincode {
  async Init(stub) {
    const ret = stub.getFunctionAndParameters();
    console.info(ret);
    console.info('=========== Instantiated Chaincode ===========');
    return _fabricShim.default.success();
  }

  async Invoke(stub) {
    console.info('########################################');
    console.info(`Transaction ID: ${stub.getTxID()}`);
    console.info(`Args: ${stub.getArgs()}`);
    const ret = stub.getFunctionAndParameters();
    console.info(ret);
    const method = this[ret.fcn]; // Verifies if method exist

    if (!method) {
      return _fabricShim.default.error(`funcao com nome "${ret.fcn}" nao encontrado`);
    }

    try {
      const payload = await method(stub, ret.params, this);
      return _fabricShim.default.success(payload);
    } catch (err) {
      console.log(err.stack);
      return _fabricShim.default.error(err.message ? err.message : 'Ocorreu um erro, Por favor tente novamente mais tarde');
    }
  }

  async getDataById(stub, args) {
    // Gets id
    const data = args[0]; // Verifies id is not empty

    if (!data) {
      throw new Error('Por favor especifique um id');
    }

    console.info('--- start getDataById ---');
    const dataAsBytes = await stub.getState(data);
    console.info('==================');
    console.log(dataAsBytes.toString());
    console.info('==================');
    console.info('--- end getDataById ---');
    return dataAsBytes;
  } // The keys are returned by the iterator in lexical order. Note that startKey and endKey can be empty string
  // Query is re-executed during validation phase


  async getDataByRange(stub, args, thisClass) {
    let data; // 1. Parses JSON stringified request

    try {
      data = JSON.parse(args.toString());
    } catch (err) {
      throw new Error('Não foi possivel decodificar o JSON, por favor verifique o formato');
    } // 2. Gets identifier


    const {
      startKey,
      endKey
    } = data;

    if (startKey === undefined || endKey === undefined) {
      throw new Error('startKey/endKey nao pode ser "undefined"');
    }

    console.info('--- start getDataByRange ---');
    const resultsIterator = await stub.getStateByRange(startKey, endKey);
    const method = thisClass['getAllResults'];
    const results = await method(resultsIterator, false);
    console.info('--- end getDataByRange ---');
    return Buffer.from(JSON.stringify(results));
  }

  async createOrganizacao(stub, args) {
    try {
      await Organizacao.createOrganizacao(stub, args);
    } catch (err) {
      throw err;
    }
  }

  async updateOrganizacao(stub, args) {
    try {
      await Organizacao.updateOrganizacao(stub, args);
    } catch (err) {
      throw err;
    }
  }

  async deleteOrganizacao(stub, args) {
    try {
      await Organizacao.deleteOrganizacao(stub, args);
    } catch (err) {
      throw err;
    }
  } // Rich Query (Only supported if CouchDB is used as state database):
  // ex: peer chaincode query -C myc -n mycc -c '{"Args":["richQuery","{\"selector\":{\"docType\":\"batch\"}}"]}'


  async richQuery(stub, args, thisClass) {
    let data;
    let method;
    let params; // 1. Parses JSON stringified request

    try {
      data = JSON.parse(args.toString());
    } catch (err) {
      throw new Error('Não foi possivel decodificar o JSON, por favor verifique o formato');
    } // Verifies if queryString is passed


    if (!data.queryString) {
      throw new Error('queryString nao pode ser vazio');
    }

    const queryString = JSON.stringify(data.queryString); // If pagination params are passed gets QueryResult with pagination

    if (data.pagination && data.pagination.pageSize) {
      params = {
        queryString,
        pagination: data.pagination
      };
      method = thisClass['getQueryResultForQueryStringWithPagination'];
    } else {
      params = queryString;
      method = thisClass['getQueryResultForQueryString'];
    }

    let queryResults;

    try {
      queryResults = await method(stub, params, thisClass);
    } catch (err) {
      throw err;
    }

    return queryResults;
  } // getQueryResultForQueryString executes the query passed in query string.


  async getQueryResultForQueryString(stub, queryString, thisClass) {
    try {
      console.info('- getQueryResultForQueryString ---');
      const resultsIterator = await stub.getQueryResult(queryString);
      const method = thisClass['getAllResults'];
      const results = await method(resultsIterator, false);
      console.log('--- end using getQueryResultForQueryString ---');
      return Buffer.from(JSON.stringify(results));
    } catch (err) {
      throw err;
    }
  } // ====== Pagination =========================================================================
  // queryString, pageSize, bookmark


  async getQueryResultForQueryStringWithPagination(stub, args, thisClass) {
    try {
      console.log('--- start using getQueryResultForQueryStringWithPagination ---');
      const {
        queryString,
        pagination
      } = args;
      const pageSize = parseInt(pagination.pageSize, 10);
      const bookmark = pagination.bookmark || '';
      const {
        iterator,
        metadata
      } = await stub.getQueryResultWithPagination(queryString, pageSize, bookmark);
      const getAllResults = thisClass['getAllResults'];
      const results = await getAllResults(iterator, false); // use RecordsCount and Bookmark to keep consistency with the go sample

      results.ResponseMetadata = {
        RecordsCount: metadata.fetched_records_count,
        Bookmark: metadata.bookmark
      };
      console.log('--- end using getQueryResultForQueryStringWithPagination ---');
      return Buffer.from(JSON.stringify(results));
    } catch (err) {
      throw err;
    }
  }

  async getAllResults(iterator, isHistory) {
    const allResults = [];

    while (true) {
      /* eslint-disable no-await-in-loop */
      const res = await iterator.next();

      if (res.value && res.value.value.toString()) {
        const jsonResponse = {}; // console.log(res.value.value.toString("utf8"));

        if (isHistory && isHistory === true) {
          jsonResponse.TxId = res.value.tx_id;
          jsonResponse.Timestamp = res.value.timestamp;
          jsonResponse.IsDelete = res.value.is_delete.toString();

          try {
            jsonResponse.Value = JSON.parse(res.value.value.toString('utf8'));
          } catch (err) {
            console.log(err);
            jsonResponse.Value = res.value.value.toString('utf8');
          }
        } else {
          jsonResponse.Key = res.value.key;

          try {
            jsonResponse.Record = JSON.parse(res.value.value.toString('utf8'));
          } catch (err) {
            console.log(err);
            jsonResponse.Record = res.value.value.toString('utf8');
          }
        }

        allResults.push(jsonResponse);
      }

      if (res.done) {
        console.log('end of data');
        await iterator.close();
        console.info(JSON.stringify(allResults));
        return allResults;
      }
    }
  }

  async getHistory(stub, args, thisClass) {
    try {
      if (args.length < 1) {
        throw new Error('Incorrect number of arguments. Expecting an id to look for');
      }

      const id = args[0];
      console.info(`--- start getHistoryFor:\n ${id}`);
      const resultsIterator = await stub.getHistoryForKey(id);
      const method = thisClass['getAllResults'];
      const results = await method(resultsIterator, true);
      return Buffer.from(JSON.stringify(results));
    } catch (err) {
      throw err;
    }
  }

}

exports.default = Chaincode;
//# sourceMappingURL=chaincode.js.map