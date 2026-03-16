-- 1. Table des types d'abonnement (le catalogue)
CREATE TABLE SubscriptionType (
    type_name VARCHAR(50) PRIMARY KEY,
    price DECIMAL(10, 2) NOT NULL
);

-- 2. Table des utilisateurs
CREATE TABLE Users (
    user_email VARCHAR(100) PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Table des abonnements (Garantit 1 abonnement max par utilisateur)
-- L'utilisation de user_email comme PRIMARY KEY assure l'unicité par utilisateur.
CREATE TABLE Subscription (
    user_email VARCHAR(100) NOT NULL,
    type_name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    PRIMARY KEY (user_email, start_date), -- Permet plusieurs abonnements dans le temps, mais pas simultanément
    FOREIGN KEY (user_email) REFERENCES Users(user_email) ON DELETE CASCADE,
    FOREIGN KEY (type_name) REFERENCES SubscriptionType(type_name)
);

-- 4. Table des publications
CREATE TABLE Post (
    author_email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    likes_count INT DEFAULT 0,
    reporting_count INT DEFAULT 0,
    PRIMARY KEY (author_email, created_at),
    FOREIGN KEY (author_email) REFERENCES Users(user_email) ON DELETE CASCADE
);

-- 5. Table des médias (Plusieurs médias possibles par post)
CREATE TABLE Media (
    id_media INT AUTO_INCREMENT PRIMARY KEY,
    author_email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    url VARCHAR(255) NOT NULL,
    type VARCHAR(20), -- 'image' ou 'video'
    FOREIGN KEY (author_email, created_at) REFERENCES Post(author_email, created_at) ON DELETE CASCADE
);