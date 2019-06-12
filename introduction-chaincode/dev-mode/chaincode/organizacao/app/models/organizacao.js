import * as yup from 'yup'; // for everything

/* eslint-disable implicit-arrow-linebreak, operator-linebreak */
export const createOrganizacao = yup.object().shape({
  docType: yup
    .string()
    .default('organizacao')
    .test('is-docType-exist', 'Por favor especifique organizacao docType', value => value === 'organizacao'),
  cnpj: yup.string().required(),
  nome: yup.string().required(),
  email: yup
    .string()
    .lowercase()
    .ensure(),
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

export const updateOrganizacao = yup.object().shape({
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
