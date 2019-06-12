import { expect } from 'chai';
import { ChaincodeMockStub } from '@theledger/fabric-mock-stub';
import Chaincode from '../app/chaincode';

const MyChaincode = new Chaincode();

describe('Test Organizacao chaincode', () => {
  const mockStub = new ChaincodeMockStub('MyMockStub', MyChaincode);

  it('Should init without issues', async () => {
    const response = await mockStub.mockInit('tx1', []);
    expect(response.status).to.equal(200);
  });

  it('I can create an organizacao', async () => {
    const response = await mockStub.mockInvoke('tx1', [
      'createOrganizacao',
      JSON.stringify({
        nome: 'test',
        cnpj: 'test'
      })
    ]);
    expect(response.status).to.equal(200);
  });

  it('I can update an organizacao', async () => {
    await mockStub.mockInvoke('tx1', [
      'updateOrganizacao',
      JSON.stringify({
        nome: 'test_updated',
        cnpj: 'test'
      })
    ]);

    const dataUpdated = await mockStub.mockInvoke('tx1', ['getDataById', 'test']);
    expect(JSON.parse(dataUpdated.payload).nome).to.equal('test_updated');
  });

  it('I can delete an organizacao', async () => {
    const response = await mockStub.mockInvoke('tx1', ['deleteOrganizacao', 'test']);
    expect(response.status).to.equal(200);
  });
});
