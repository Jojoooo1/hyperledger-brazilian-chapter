// import { performance } from 'perf_hooks';
import * as Schema from '../models/organizacao';

const validationOptions = { recursive: true, abortEarly: true, stripUnknown: true };

export const createOrganizacao = async (stub, args) => {
  let data;
  let formattedData;

  // 1. Parse JSON stringified request
  try {
    data = JSON.parse(args.toString('utf8'));
  } catch (err) {
    throw new Error('Não foi possivel decodificar o JSON, por favor verifique o formato');
  }

  console.info('--- start createOrganizacao ---');

  // 2. Get identifier
  const id = data.cnpj;

  if (!id) {
    throw new Error('Por favor especifique o cnpj');
  }

  // 3. Verifies data does not exist
  let dataAsBytes = await stub.getState(id);
  if (dataAsBytes.toString('utf8')) {
    throw new Error(`Organizacao com cnpj ${id} ja existe`);
  }

  // const t0 = performance.now();
  // 4. Verifies Object format
  try {
    formattedData = await Schema.createOrganizacao.validate(data, validationOptions);
  } catch (err) {
    throw err;
  }
  // const t1 = performance.now();
  // console.log(`Call took ${t1 - t0} ms.`);

  // 5. Sets Date information (not 100% reliable)
  formattedData.createdAt = new Date(stub.getTxTimestamp().getSeconds() * 1000).toISOString();
  formattedData.updatedAt = formattedData.createdAt;

  // 6. Transforms JSON into Bytes data
  dataAsBytes = Buffer.from(JSON.stringify(formattedData));
  // 7. Pushes updated data into the ledger
  await stub.putState(id, dataAsBytes);
  // 8. Creates event
  stub.setEvent('organizacaoCreated', dataAsBytes);

  console.info('==================');
  console.log(formattedData);
  console.info('==================');
  console.info('--- end createOrganizacao ---');
};

export const updateOrganizacao = async (stub, args) => {
  let data;
  let formattedData;

  // 1. Parses JSON stringified request
  try {
    data = JSON.parse(args.toString('utf8'));
  } catch (err) {
    throw new Error('Não foi possivel decodificar o JSON, por favor verifique o formato');
  }

  console.info('--- start updateOrganizacao ---');

  // 2. Get identifier
  const id = data.cnpj;
  if (!id) {
    throw new Error('Por favor especifique o cnpj');
  }

  // 3. Verifies if data already exist
  let dataAsBytes = await stub.getState(id);
  if (!dataAsBytes.toString('utf8')) {
    throw new Error(`Organizacao com cnpj ${id} nao encontrado`);
  }

  // 4. Verifies Object format
  try {
    formattedData = await Schema.updateOrganizacao.validate(data, validationOptions);
  } catch (err) {
    throw err;
  }

  // 5. Parses data that will be updated
  const dataToUpdate = JSON.parse(dataAsBytes.toString('utf8'));
  // 6. Merges updated organizacao into organizacao to update -> Possibles to use specific merging function/lib to only update modified fields
  const updatedData = { ...dataToUpdate, ...formattedData };
  // 6.1 Updates updateAt
  updatedData.updatedAt = new Date(stub.getTxTimestamp().getSeconds() * 1000).toISOString();
  // 7. Transforms the JSON data into Bytes data
  dataAsBytes = Buffer.from(JSON.stringify(updatedData));

  // 8. Pushes updated data into the ledger
  await stub.putState(id, dataAsBytes);

  // 9. Sends event
  stub.setEvent('organizacaoUpdated', dataAsBytes);
  console.info('==================');
  console.log(updatedData);
  console.info('==================');
  console.info('--- end updateOrganizacao ---');
};

export const deleteOrganizacao = async (stub, args) => {
  const cnpj = args[0];

  // 1. Verifies identifier is not empty
  if (!cnpj) {
    throw new Error('Por favor especifique o cnpj');
  }

  console.log('--- start deleteOrganizacao ---');

  // 2. Verifies if data already exists
  const dataAsBytes = await stub.getState(cnpj);
  if (!dataAsBytes.toString('utf8')) {
    throw new Error(`Organizacao com cnpj "${cnpj}" nao encontrado`);
  }

  // 3. Deletes data
  await stub.deleteState(cnpj);

  // 4. Sends event
  stub.setEvent('organizacaoRemoved', dataAsBytes);
  console.info('==================');
  console.log(`organizacao com cnpj "${cnpj}" foi deletado`);
  console.info('==================');
  console.info('--- end deleteOrganizacao ---');
};
