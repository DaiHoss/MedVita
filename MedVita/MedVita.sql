CREATE DATABASE IF NOT EXISTS medvita

CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE medvita;
 
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
 
 
 
 
 
 
 