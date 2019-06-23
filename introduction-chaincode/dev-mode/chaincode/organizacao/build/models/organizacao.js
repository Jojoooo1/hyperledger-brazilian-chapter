"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.updateOrganizacao = exports.createOrganizacao = void 0;

var yup = _interopRequireWildcard(require("yup"));

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = Object.defineProperty && Object.getOwnPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : {}; if (desc.get || desc.set) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } } newObj.default = obj; return newObj; } }

// for everything

/* eslint-disable implicit-arrow-linebreak, operator-linebreak */
const createOrganizacao = yup.object().shape({
  docType: yup.string().default('organizacao').test('is-docType-exist', 'Por favor especifique organizacao docType', value => value === 'organizacao'),
  cnpj: yup.string().required(),
  nome: yup.string().required(),
  email: yup.string().lowercase().ensure(),
  endereco: yup.object().shape({
    rua: yup.string().ensure(),
    numero: yup.string().ensure(),
    complemento: yup.string().ensure(),
    referencia: yup.string().ensure(),
    bairro: yup.string().ensure(),
    cep: yup.string().ensure(),
    cidade: yup.string().ensure(),
    uf: yup.string().ensure()
  })
});
exports.createOrganizacao = createOrganizacao;
const updateOrganizacao = yup.object().shape({
  nome: yup.string().lowercase(),
  email: yup.string().lowercase(),
  endereco: yup.object().shape({
    rua: yup.string().ensure(),
    numero: yup.string().ensure(),
    complemento: yup.string().ensure(),
    referencia: yup.string().ensure(),
    bairro: yup.string().ensure(),
    cep: yup.string().ensure(),
    cidade: yup.string().ensure(),
    uf: yup.string().ensure()
  })
});
exports.updateOrganizacao = updateOrganizacao;
//# sourceMappingURL=organizacao.js.map