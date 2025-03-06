const express = require('express');
const mysql = require('mysql2/promise'); // Importação do mysql2 com promises
const bodyParser = require('body-parser');
const cors = require('cors');
const moment = require('moment');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Configuração do pool de conexões MySQL
const pool = mysql.createPool({
    host: '193.203.175.126',
    user: 'u565643099_gsantos',
    password: '@Biel1234567',
    database: 'u565643099_gastos',
    waitForConnections: true,
    connectionLimit: 10,  // Número máximo de conexões simultâneas
});

// Função para pegar uma conexão do pool
const getConnection = () => {
    return pool.getConnection();
};

// Rota de login
app.post('/login', async (req, res) => {
    const { email, senha } = req.body;

    if (!email || !senha) {
        return res.status(400).json({ message: 'Email e senha são obrigatórios' });
    }

    try {
        const [results] = await pool.query('SELECT id, nome_completo, senha FROM usuarios WHERE email = ?', [email]);

        if (results.length === 0) {
            return res.status(401).json({ message: 'Credenciais inválidas' });
        }

        const user = results[0];

        if (senha !== user.senha) {
            return res.status(401).json({ message: 'Credenciais inválidas' });
        }

        return res.status(200).json({
            success: true,
            id: user.id,
        });
    } catch (err) {
        console.error('Erro na consulta ao banco de dados:', err);
        return res.status(500).json({ message: 'Erro no servidor' });
    }
});

// Rota de cadastro de usuário
app.post('/usuario', async (req, res) => {
    const { nome_completo, email, senha } = req.body;

    if (!nome_completo || !email || !senha) {
        return res.status(400).json({ error: 'Todos os campos são obrigatórios' });
    }

    try {
        const [rows] = await pool.query('SELECT id FROM usuarios WHERE email = ?', [email]);

        if (rows.length > 0) {
            return res.status(400).json({ error: 'E-mail já cadastrado' });
        }

        const query = 'INSERT INTO usuarios (nome_completo, email, senha) VALUES (?, ?, ?)';
        await pool.query(query, [nome_completo, email, senha]);

        res.status(201).json({ message: 'Usuário cadastrado com sucesso!' });
    } catch (err) {
        console.error('Erro na conexão ou execução da query:', err);
        res.status(500).json({ error: 'Erro ao conectar ao banco de dados' });
    }
});

// Adicionar uma conta
app.post('/contas', async (req, res) => {
    const { user_id, titulo, valor, data_vencimento, eh_recorrente, dia_recorrencia } = req.body;

    // Verificar se todos os campos obrigatórios estão presentes
    if (!user_id || !titulo || !valor || !data_vencimento || eh_recorrente === undefined) {
        return res.status(400).json({ error: 'Todos os campos obrigatórios são necessários' });
    }

    // Validar o formato da data de vencimento (dd/mm/aaaa)
    const dataVencimentoRegex = /^\d{2}\/\d{2}\/\d{4}$/;
    if (!dataVencimentoRegex.test(data_vencimento)) {
        return res.status(400).json({ error: 'Formato de data de vencimento inválido. Use dd/mm/aaaa.' });
    }

    // Validar se eh_recorrente é um booleano
    if (typeof eh_recorrente !== 'boolean') {
        return res.status(400).json({ error: 'O campo eh_recorrente deve ser um booleano' });
    }

    // Validar dia_recorrencia se eh_recorrente for true
    if (eh_recorrente) {
        const diaRecorrenciaConvertido = parseInt(dia_recorrencia, 10);

        if (diaRecorrenciaConvertido < 1 || diaRecorrenciaConvertido > 31) {
            return res.status(400).json({ error: 'Dia de recorrência inválido. Deve ser entre 1 e 31.' });
        }
    }

    try {
        // Converter a data de vencimento para o formato do banco de dados (aaaa-mm-dd)
        const [dia, mes, ano] = data_vencimento.split('/');
        const dataVencimentoFormatada = `${ano}-${mes}-${dia}`;

        // Preparar a query para inserção
        const query = `
            INSERT INTO conta (user_id, titulo, valor, data_conta, eh_mensal, dia_conta)
            VALUES (?, ?, ?, ?, ?, ?)
        `;
        const values = [
            user_id,
            titulo,
            valor,
            dataVencimentoFormatada, // data_conta no formato aaaa-mm-dd
            eh_recorrente, // eh_mensal (booleano)
            eh_recorrente ? dia_recorrencia : null, // dia_conta (só preenche se for recorrente)
        ];

        // Executar a query
        await pool.query(query, values);

        // Resposta após sucesso
        console.log('Conta cadastrada com sucesso');
        res.status(201).json({ message: 'Conta cadastrada com sucesso!' });
    } catch (err) {
        // Exibir erro completo no log
        console.error('Erro na execução da query:', err);
        // Responder com detalhes do erro
        res.status(500).json({ error: 'Erro ao adicionar conta', details: err.message || err });
    }
});

app.post('/gastos', async (req, res) => {
    const {
      user_id,
      categoria,
      titulo,
      valor,
      data,
      forma_pagamento,
      quantidade_parcelas,
    } = req.body;
  
  
    // Verificar se todos os campos obrigatórios estão presentes
    if (
      !user_id ||
      !categoria ||
      !titulo ||
      !valor ||
      !data ||
      !forma_pagamento ||
      !quantidade_parcelas
    ) {
      return res.status(400).json({ error: 'Todos os campos são obrigatórios' });
    }
  

  
    // Verificar se a data está no formato correto (dd/mm/yyyy)
    const dataRegex = /^\d{2}\/\d{2}\/\d{4}$/;
    if (!dataRegex.test(data)) {
      return res.status(400).json({ error: 'Formato de data inválido (use dd/mm/yyyy)' });
    }
  
    // Converter a data para o formato do MySQL (yyyy-mm-dd)
    const [dia, mes, ano] = data.split('/');
    const dataConvertida = `${ano}-${mes}-${dia}`;
  
    try {
      // Preparar a query para inserção
      const query = `
        INSERT INTO gasto 
        (user_id, categoria, titulo, valor, data, forma_pagamento, quantidade_parcelas) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `;

  
      // Executar a query
      await pool.query(query, [
        user_id,
        categoria,
        titulo,
        valor,
        dataConvertida,
        forma_pagamento,
        quantidade_parcelas,
      ]);
  
      // Resposta após sucesso
      console.log('Gasto cadastrado com sucesso');
      res.status(201).json({ message: 'Gasto cadastrado com sucesso!' });
    } catch (err) {
      // Exibir erro completo no log
      console.error('Erro na execução da query:', err);
      // Responder com detalhes do erro
      res.status(500).json({ error: 'Erro ao adicionar gasto', details: err.message || err });
    }
  });

// Buscar todos os gastos
app.get('/gastos', async (req, res) => {
  try {
      const { user_id, mes, parcelado } = req.query;
      let query = 'SELECT * FROM gasto WHERE 1=1';
      let params = [];

      if (user_id) {
          query += ' AND user_id = ?';
          params.push(user_id);
      }

      if (mes) {
          query += ' AND (';
          query += 'DATE_FORMAT(data, "%Y-%m") = ?'; // Mês da compra original
          params.push(mes);
          query += ' OR (quantidade_parcelas > 1 AND DATE_ADD(data, INTERVAL (quantidade_parcelas - 1) MONTH) >= ?)';
          params.push(`${mes}-01`); // Filtra parcelas futuras dentro do mês
          query += ')';
      }

      if (parcelado === 'true') {
          query += ' AND quantidade_parcelas > 1';
      }

      const [results] = await pool.query(query, params);

      // Ajusta parcelas futuras
      let gastosFormatados = [];
      results.forEach(gasto => {
          const dataCompra = new Date(gasto.data);
          for (let i = 0; i < gasto.quantidade_parcelas; i++) {
              let parcelaData = new Date(dataCompra);
              parcelaData.setMonth(parcelaData.getMonth() + i);

              let parcelaMes = parcelaData.toISOString().slice(0, 7); // Formato YYYY-MM
              if (mes && parcelaMes !== mes) continue; // Filtra apenas o mês desejado

              gastosFormatados.push({
                  ...gasto,
                  data: parcelaData.toISOString().slice(0, 10),
                  parcela_atual: `${i + 1}/${gasto.quantidade_parcelas}x`
              });
          }
      });

      res.json(gastosFormatados);
  } catch (err) {
      console.error('Erro na conexão:', err);
      res.status(500).json({ error: 'Erro ao buscar gastos' });
  }
});

app.get('/contas', async (req, res) => {
  try {
      const { user_id, mes, ano, eh_mensal } = req.query;

      let query = 'SELECT * FROM conta WHERE user_id = ?';
      let params = [user_id];

      if (mes && ano) {
          query += ' AND DATE_FORMAT(data_conta, "%Y-%m") = ?';
          params.push(`${ano}-${mes.padStart(2, '0')}`);
      }

      if (eh_mensal) {
          query += ' AND eh_mensal = ?';
          params.push(eh_mensal);
      }

      const [results] = await pool.query(query, params);

      res.json(results);
  } catch (err) {
      console.error('Erro na conexão:', err);
      res.status(500).json({ error: 'Erro ao buscar contas' });
  }
});

app.post('/conta_paga', async (req, res) => {
  try {
    const { conta_id, data_pagamento } = req.body;
    const query = 'INSERT INTO conta_paga (conta_id, data_pagamento) VALUES (?, ?)';
    const params = [conta_id, data_pagamento];

    await pool.query(query, params);
    res.status(200).json({ message: 'Conta marcada como paga' });
  } catch (err) {
    console.error('Erro ao marcar como pago:', err);
    res.status(500).json({ error: 'Erro ao marcar como pago' });
  }
});

app.delete('/contas/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const query = 'DELETE FROM conta WHERE id = ?';
    const params = [id];

    await pool.query(query, params);
    res.status(200).json({ message: 'Conta excluída com sucesso' });
  } catch (err) {
    console.error('Erro ao excluir conta:', err);
    res.status(500).json({ error: 'Erro ao excluir conta' });
  }
});

app.delete('/gastos/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const query = 'DELETE FROM gasto WHERE id = ?';
    const params = [id];

    await pool.query(query, params);
    res.status(200).json({ message: 'Gasto excluído com sucesso' });
  } catch (err) {
    console.error('Erro ao excluir gasto:', err);
    res.status(500).json({ error: 'Erro ao excluir gasto' });
  }
});

app.get('/conta_paga', async (req, res) => {
  try {
    const { conta_id, mes, ano } = req.query;
    const query = 'SELECT * FROM conta_paga WHERE conta_id = ? AND DATE_FORMAT(data_pagamento, "%Y-%m") = ?';
    const params = [conta_id, `${ano}-${mes}`];

    const [results] = await pool.query(query, params);
    res.json(results);
  } catch (err) {
    console.error('Erro ao buscar pagamentos:', err);
    res.status(500).json({ error: 'Erro ao buscar pagamentos' });
  }
});

app.get('/contas/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const query = 'SELECT * FROM conta WHERE id = ?';
    const params = [id];

    const [results] = await pool.query(query, params);
    res.json(results[0]); // Retorna a primeira linha (única conta)
  } catch (err) {
    console.error('Erro ao buscar conta:', err);
    res.status(500).json({ error: 'Erro ao buscar conta' });
  }
});

app.get('/contas/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const query = 'SELECT * FROM conta WHERE id = ?';
    const params = [id];

    const [results] = await pool.query(query, params);
    res.json(results[0]); // Retorna a primeira linha (única conta)
  } catch (err) {
    console.error('Erro ao buscar conta:', err);
    res.status(500).json({ error: 'Erro ao buscar conta' });
  }
});
function formatarData(data) {
  const partes = data.split('/');
  return `${partes[2]}-${partes[1]}-${partes[0]}`;
}

app.put('/contas/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { titulo, valor, data_conta, data_vencimento, is_conta_mensal } = req.body;
    console.log(titulo, valor, data_conta, data_vencimento, is_conta_mensal)

    // Verificar se o dia de pagamento é válido (de 1 a 31)
    const diaPagamentoValido = Math.min(Math.max(data_vencimento, 1), 31);

    // Convertendo a data de dd/MM/yyyy para yyyy-MM-dd
    const dataContasFormatada = formatarData(data_conta);

    // Convertendo o valor de conta_mensal para 1 (sim) ou 0 (não)
    const ehMensal = is_conta_mensal ? 1 : 0;

    // Se não for mensal, o campo dia_conta deve ser null
    const diaConta = ehMensal ? diaPagamentoValido : null;

    // Alterar a query para incluir os campos dia_pagamento e conta_mensal
    const query = 'UPDATE conta SET titulo = ?, valor = ?, data_conta = ?, eh_mensal = ?, dia_conta = ? WHERE id = ?';
    const params = [titulo, valor, dataContasFormatada, ehMensal, diaConta, id];

    await pool.query(query, params);
    res.status(200).json({ message: 'Conta atualizada com sucesso' });
  } catch (err) {
    console.error('Erro ao atualizar conta:', err);
    res.status(500).json({ error: 'Erro ao atualizar conta' });
  }
});




app.put('/gastos/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const { categoria, titulo, valor, data, forma_pagamento, parcela_atual } = req.body;
    // Formatar a data para yyyy-mm-dd
    const formattedDate = moment(data, 'DD/MM/YYYY').format('YYYY-MM-DD');

    const query = `
      UPDATE gasto 
      SET 
        categoria = ?, 
        titulo = ?, 
        valor = ?, 
        data = ?, 
        forma_pagamento = ?, 
        quantidade_parcelas = ? 
      WHERE id = ?`;

    const params = [ categoria, titulo, valor, formattedDate, forma_pagamento, parcela_atual, id];

    await pool.query(query, params);
    res.status(200).json({ message: 'Gasto atualizado com sucesso' });
  } catch (err) {
    console.error('Erro ao atualizar gasto:', err);
    res.status(500).json({ error: 'Erro ao atualizar gasto' });
  }
});

app.post('/ganhos', async (req, res) => {
    const { user_id, descricao, valor, data_recebimento, eh_recorrente, dia_vencimento } = req.body;

    // Validação dos dados
    if (!user_id || !descricao || !valor || !data_recebimento || eh_recorrente === undefined) {
        return res.status(400).send({ status: 'Todos os campos são obrigatórios' });
    }

    // Validação da data (formato AAAA-MM-DD)
    const regexData = /^\d{4}-\d{2}-\d{2}$/;
    if (!regexData.test(data_recebimento)) {
        return res.status(400).send({ status: 'Data inválida. Use o formato AAAA-MM-DD.' });
    }

    const dataValida = !isNaN(Date.parse(data_recebimento)) && Date.parse(data_recebimento) > Date.parse('1000-01-01');
    if (!dataValida) {
        return res.status(400).send({ status: 'Data inválida. Use uma data após 1000-01-01.' });
    }

    // Verificar se eh_recorrente é um booleano
    if (typeof eh_recorrente !== 'boolean') {
        return res.status(400).send({ status: 'O campo eh_recorrente deve ser um booleano' });
    }

    // Verificar se o dia do vencimento é válido (apenas se o ganho for recorrente)
    if (eh_recorrente) {
        if (!dia_vencimento || isNaN(dia_vencimento) || dia_vencimento < 1 || dia_vencimento > 31) {
            return res.status(400).send({ status: 'Dia do vencimento inválido. Deve ser entre 1 e 31.' });
        }
    }

    try {
        const query = `
            INSERT INTO ganho (user_id, descricao, valor, data_recebimento, eh_recorrente, dia_ganho)
            VALUES (?, ?, ?, ?, ?, ?)
        `;

        const [result] = await pool.query(query, [
            user_id,
            descricao,
            valor,
            data_recebimento,
            eh_recorrente,
            eh_recorrente ? dia_vencimento : null, // Envia o dia do vencimento apenas se for recorrente
        ]);

        console.log('Ganho cadastrado com sucesso');

        // Envia apenas uma resposta
        res.status(201).json({ 
            message: 'Ganho cadastrado com sucesso!', 
            id: result.insertId 
        });
    } catch (err) {
        console.error('Erro inesperado:', err);
        res.status(500).send({ status: 'Erro no servidor' });
    }
});

const getMesAnoAtual = () => {
    const now = new Date();
    return {
      mes: now.getMonth() + 1, // Mês atual (1 a 12)
      ano: now.getFullYear(), // Ano atual
    };
  };

app.get('/totais/:user_id', async (req, res) => {
    const { user_id } = req.params;
    const { mes, ano } = getMesAnoAtual(); // Usa a função getMesAnoAtual
  
    try {
      // Consulta total de contas do mês atual
      const [contas] = await pool.query(
        `SELECT SUM(valor) AS total_contas 
         FROM conta 
         WHERE user_id = ? AND MONTH(data_conta) = ? AND YEAR(data_conta) = ?`,
        [user_id, mes, ano]
      );
  
      // Consulta total de gastos do mês atual
      const [gastos] = await pool.query(
        `SELECT SUM(valor) AS total_gastos 
         FROM gasto 
         WHERE user_id = ? AND MONTH(data) = ? AND YEAR(data) = ?`,
        [user_id, mes, ano]
      );
  
      // Consulta total de ganhos do mês atual
      const [ganhos] = await pool.query(
        `SELECT SUM(valor) AS total_ganhos 
         FROM ganho 
         WHERE user_id = ? AND MONTH(data_recebimento) = ? AND YEAR(data_recebimento) = ?`,
        [user_id, mes, ano]
      );
  
      // Retorna os totais
      res.status(200).json({
        total_contas: contas[0].total_contas || 0,
        total_gastos: gastos[0].total_gastos || 0,
        total_ganhos: ganhos[0].total_ganhos || 0,
      });
    } catch (err) {
      console.error('Erro ao calcular totais:', err);
      res.status(500).json({ error: 'Erro ao calcular totais' });
    }
  });

  app.get('/ultimos-gastos/:user_id', async (req, res) => {
    const { user_id } = req.params;
  
    try {
      const [rows] = await pool.query(
        `SELECT id, categoria, titulo, valor, data 
         FROM gasto 
         WHERE user_id = ? 
         ORDER BY data DESC 
         LIMIT 5`,
        [user_id]
      );
      res.status(200).json(rows);
    } catch (err) {
      console.error('Erro ao consultar últimos gastos:', err);
      res.status(500).json({ error: 'Erro ao consultar últimos gastos' });
    }
  });

  app.get('/ultimas-contas/:user_id', async (req, res) => {
    const { user_id } = req.params;
  
    try {
      const [rows] = await pool.query(
        `SELECT id, titulo, valor, data_conta 
         FROM conta 
         WHERE user_id = ? 
         ORDER BY data_conta DESC 
         LIMIT 5`,
        [user_id]
      );
      res.status(200).json(rows);
    } catch (err) {
      console.error('Erro ao consultar últimas contas:', err);
      res.status(500).json({ error: 'Erro ao consultar últimas contas' });
    }
  });

  app.get('/contas-recorrentes/:user_id', async (req, res) => {
    const { user_id } = req.params;
  
    try {
      // Consulta ao banco de dados
      const [rows] = await pool.query(
        `SELECT id, titulo, valor, dia_conta 
         FROM conta
         WHERE user_id = ? and eh_mensal=1`,
        [user_id]
      );

      res.status(200).json(rows);
    } catch (err) {
      console.error('Erro ao consultar contas recorrentes:', err);
      res.status(500).json({ error: 'Erro ao consultar contas recorrentes' });
    }
});

  app.get('/gastos-parcelados/:user_id', async (req, res) => {
    const { user_id } = req.params;
  
    try {
      // Consulta ao banco de dados
      const [rows] = await pool.query(
        `SELECT id, categoria, titulo, valor, data, forma_pagamento, quantidade_parcelas 
         FROM gasto 
         WHERE user_id = ? AND quantidade_parcelas > 1`,
        [user_id]
      );

      const hoje = new Date();
      const gastosComParcelas = rows.map((gasto) => {
        const parcelas = [];
        const dataInicial = new Date(gasto.data);
        const valorParcela = parseFloat(gasto.valor.replace(',', '.')) / gasto.quantidade_parcelas;
  
        for (let i = 0; i < gasto.quantidade_parcelas; i++) {
          const dataParcela = new Date(dataInicial);
          dataParcela.setMonth(dataInicial.getMonth() + i);
  
          parcelas.push({
            titulo: `${gasto.titulo} (Parcela ${i + 1}/${gasto.quantidade_parcelas})`,
            valor: valorParcela.toFixed(2),
            data: dataParcela.toISOString().split('T')[0], // Formato YYYY-MM-DD
          });
        }
  
        return {
          ...gasto,
          parcelas,
        };
      });


      res.status(200).json(gastosComParcelas);
    } catch (err) {
      console.error('Erro ao consultar gastos parcelados:', err);
      res.status(500).json({ error: 'Erro ao consultar gastos parcelados' });
    }
});
// Iniciar o servidor
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
});
