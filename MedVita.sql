CREATE DATABASE IF NOT EXISTS medvita

CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE medvita;

CREATE TABLE medico (
  id_medico   INT AUTO_INCREMENT PRIMARY KEY,
  nome        VARCHAR(150) NOT NULL,
  crm         VARCHAR(20)  NOT NULL UNIQUE,
  telefone    VARCHAR(20),
  email       VARCHAR(150),
  ativo       TINYINT(1)   DEFAULT 1,
  criado_em   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);
 
CREATE TABLE especialidade(
  id_especialidade INT PRIMARY KEY auto_increment, 
  nome VARCHAR(100) NOT NULL, 
  descricao TEXT
);
 
CREATE TABLE paciente(
  id_paciente INT PRIMARY KEY auto_increment, 
  nome VARCHAR(150) NOT NULL, 
  cpf VARCHAR(255) NOT NULL UNIQUE,   -- criptografado AES 
  data_nasc DATE NOT NULL, 
  sexo ENUM('M','F','O') NOT NULL, 
  telefone VARCHAR(20), 
  email VARCHAR(150), 
  endereco VARCHAR(255), 
  convenio VARCHAR(100), 
  ativo TINYINT(1) DEFAULT 1, 
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
 
);
 
 
CREATE TABLE medico_especialidade(
  id_medico INT NOT NULL, 
  id_especialidade INT NOT NULL, 
  PRIMARY KEY (id_medico, id_especialidade), 
  FOREIGN KEY (id_medico)        REFERENCES medico(id_medico), 
  FOREIGN KEY (id_especialidade) REFERENCES especialidade(id_especialidade)
);
 
 
CREATE TABLE agenda (
  id_agenda INT AUTO_INCREMENT PRIMARY KEY, 
  id_medico INT NOT NULL, 
  data_hora DATETIME NOT NULL, 
  disponivel TINYINT(1) DEFAULT 1,
  FOREIGN KEY (id_medico) REFERENCES medico(id_medico)
);
 
 
CREATE TABLE consulta(
  id_consulta INT AUTO_INCREMENT PRIMARY KEY, 
  id_paciente INT NOT NULL, 
  id_medico INT NOT NULL, 
  id_agenda INT NOT NULL, 
  data_hora DATETIME NOT NULL, 
  tipo ENUM('consulta','retorno','urgencia') DEFAULT 'consulta', 
  status ENUM('agendada','realizada','cancelada') DEFAULT 'agendada', 
  observacoes TEXT,
  FOREIGN KEY (id_paciente) REFERENCES paciente(id_paciente), 
  FOREIGN KEY (id_medico)   REFERENCES medico(id_medico), 
  FOREIGN KEY (id_agenda)   REFERENCES agenda(id_agenda)
);
 
 
CREATE TABLE prontuario(
  id_prontuario INT AUTO_INCREMENT PRIMARY KEY, 
  id_paciente INT NOT NULL UNIQUE, 
  historico TEXT, 
  alergias TEXT, 
  medicamentos TEXT, 
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (id_paciente) REFERENCES paciente(id_paciente)
);
 
 
CREATE TABLE exame(
  id_exame INT AUTO_INCREMENT PRIMARY KEY, 
  id_consulta INT NOT NULL, 
  tipo VARCHAR(100) NOT NULL, 
  resultado TEXT, 
  data_exam DATE,
  FOREIGN KEY (id_consulta) REFERENCES consulta(id_consulta)
);
 
 
CREATE TABLE receita(
  id_receita INT AUTO_INCREMENT PRIMARY KEY, 
  id_consulta INT NOT NULL, 
  id_medico INT NOT NULL, 
  medicamento VARCHAR(200) NOT NULL, 
  posologia TEXT, 
  emitida_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_consulta) REFERENCES consulta(id_consulta), 
  FOREIGN KEY (id_medico) REFERENCES medico(id_medico)
);
 
 
CREATE TABLE pagamento(
  id_pagamento INT AUTO_INCREMENT PRIMARY KEY, 
  id_consulta INT NOT NULL UNIQUE, 
  valor DECIMAL(10,2) NOT NULL, 
  forma_pag ENUM('dinheiro','cartao','pix','convenio') NOT NULL, 
  status_pag ENUM('pendente','pago','cancelado') DEFAULT 'pendente', 
  pago_em TIMESTAMP NULL,
  FOREIGN KEY (id_consulta) REFERENCES consulta(id_consulta)
);
 
 
CREATE TABLE usuario(
  id_usuario INT AUTO_INCREMENT PRIMARY KEY, 
  id_medico INT NULL, 
  login VARCHAR(80) NOT NULL UNIQUE, 
  senha_hash VARCHAR(255) NOT NULL,   -- SHA2 + SALT 
  perfil ENUM('admin','medico','recepcionista') NOT NULL, 
  ativo TINYINT(1) DEFAULT 1,
  FOREIGN KEY (id_medico) REFERENCES medico(id_medico)
);
 
 
CREATE TABLE estoque_medicamento(
  id_medicamento INT AUTO_INCREMENT PRIMARY KEY, 
  nome VARCHAR(200) NOT NULL, 
  quantidade INT DEFAULT 0, 
  unidade VARCHAR(20), 
  validade DATE, 
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


DELIMITER //
CREATE PROCEDURE sp_agendar_consulta( 
  IN p_id_paciente INT, 
  IN p_id_medico INT, 
  IN p_data_hora DATETIME, 
  IN p_tipo ENUM('consulta','retorno','urgencia') 
) 
BEGIN 
  DECLARE v_id_agenda INT; 

  -- Verifica disponibilidade 
  SELECT id_agenda INTO v_id_agenda 
  FROM agenda 
  WHERE id_medico = p_id_medico 
    AND data_hora = p_data_hora 
    AND disponivel = 1 
  LIMIT 1; 
  IF v_id_agenda IS NULL THEN 
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Horário não disponível'; 
  END IF; 

  -- Registra a consulta 
  INSERT INTO consulta (id_paciente, id_medico, id_agenda, data_hora, tipo) 
  VALUES (p_id_paciente, p_id_medico, v_id_agenda, p_data_hora, p_tipo); 

  -- Marca horário como indisponível 
  UPDATE agenda SET disponivel = 0 WHERE id_agenda = v_id_agenda; 
  SELECT LAST_INSERT_ID() AS id_consulta_gerada; 
END //
DELIMITER ; 


CREATE VIEW vw_relatorio_consultas AS 
SELECT 
  c.id_consulta, 
  p.nome AS paciente, 
  m.nome AS medico, 
  m.crm, 
  e.nome AS especialidade, 
  c.data_hora, 
  c.tipo, 
  c.status, 
  pg.valor, 
  pg.forma_pag, 
  pg.status_pag 

FROM consulta c 
JOIN paciente p ON c.id_paciente= p.id_paciente 
JOIN medico   m ON c.id_medico= m.id_medico 
LEFT JOIN medico_especialidade me ON me.id_medico = m.id_medico 
LEFT JOIN especialidade e ON e.id_especialidade = me.id_especialidade 
LEFT JOIN pagamento pg ON pg.id_consulta = c.id_consulta; 


CREATE VIEW vw_medicos_disponiveis AS 
SELECT 
  m.id_medico, 
  m.nome AS medico, 
  m.crm, e.nome AS especialidade, 
  a.data_hora AS proximo_horario 

FROM medico m 
JOIN agenda a ON a.id_medico = m.id_medico 
LEFT JOIN medico_especialidade me ON me.id_medico = m.id_medico 
LEFT JOIN especialidade e ON e.id_especialidade = me.id_especialidade 
WHERE a.disponivel = 1 
  AND a.data_hora >= NOW() 
  AND m.ativo = 1 
ORDER BY a.data_hora; 





 
 
 
 
 
 
 