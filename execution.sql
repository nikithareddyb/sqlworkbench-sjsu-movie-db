CREATE DATABASE sjsu_movie_db;

use sjsu_movie_db;

--CREATE TABLE 1: movie

CREATE TABLE movie (
    imdb_rank INT NOT NULL,
    `Title` TEXT,
    `Genre` TEXT,
    `Description` TEXT,
    `Director` TEXT,
    `Actors` TEXT,
    `Year` INT DEFAULT NULL,
    `Runtime` INT DEFAULT NULL,
    `Rating` DOUBLE DEFAULT NULL,
    `Votes` INT DEFAULT NULL,
    `Revenue` DOUBLE DEFAULT NULL,
    `Metascore` INT DEFAULT NULL,
    CONSTRAINT movie_pk PRIMARY KEY (imdb_rank)
);

-- Initially added the data into this table through INSERT statements in movie-insert.sql file on my local
--This table data will remain constant. Hence no procedure to add a record is required.

--CREATE TABLE 2: users

CREATE TABLE users (
    emailid VARCHAR(255) NOT NULL,
    phoneno VARCHAR(20),
    name VARCHAR(150),
    dob DATE,
    password VARCHAR(100),
    account_create_date DATE,
    no_of_profiles INT,
    preferred_language VARCHAR(100),
    CONSTRAINT users_pk PRIMARY KEY (emailid)
);

--Initially added the data into this table through INSERT statements in users-insert.sql
--Below procedure create_user() is used to add users into the users table

--PROCEDURE 1: CREATE A NEW USER create_user()

DELIMITER //
CREATE PROCEDURE create_user(IN email_id VARCHAR(225), user_name VARCHAR(225), phone_no VARCHAR(50), pass VARCHAR(255), d_o_b DATE, lang VARCHAR(100))
BEGIN
  INSERT INTO users(emailid, phoneno, name, account_create_date, password, dob, no_of_profiles, language) values ( email_id,phone_no, user_name, CURDATE(), pass, d_o_b, 0, English);
END //
DELIMITER ;

--CREATE TABLE 3: profiles

CREATE TABLE profiles (
    profile_name VARCHAR(50) NOT NULL,
    emailid VARCHAR(255) NOT NULL,
    service_id int NOT NULL UNIQUE AUTO_INCREMENT,
    CONSTRAINT profile_primkey PRIMARY KEY (profile_name , emailid),
    CONSTRAINT profile_foreignkey FOREIGN KEY (emailid)
        REFERENCES users (emailid)
        ON DELETE CASCADE
)  AUTO_INCREMENT=400000;

--Initially added the data into this table through INSERT statements in profiles-insert.sql

--Before creation of any profiles the below trigger is to be created so that the users table is updated with the number of profiles that are present in the users table

--TRIGGER 1: PROFILE ADDED IN PROFILES UPDATES COUNT IN USERS TABLE

DELIMITER //
CREATE TRIGGER user_profile_update
AFTER INSERT ON profiles
FOR EACH ROW
BEGIN
UPDATE users SET no_of_profiles = no_of_profiles + 1 WHERE emailid = NEW.emailid;
END //
DELIMITER ;

-- The below trigger should be executed before creating any new profile so that it doesnt allow a 6th profile to be added.

--TRIGGER 2: CHECK IF CREATION OF MORE THAN 5 PROFILES ARE BEING CREATED

DELIMITER \\
CREATE TRIGGER check_profile_count_for_insert
BEFORE INSERT ON profiles
FOR EACH ROW
BEGIN
  DECLARE count INT;
SELECT
    no_of_profiles
FROM
    users
WHERE
    emailid = NEW.emailid INTO count;
  IF count >= 5
  THEN
   SIGNAL SQLSTATE '02000' SET MESSAGE_TEXT = 'Error: Cannot add more than 5 Profiles';
  END IF;
END\\
DELIMITER ;

--Below procedure is used to add new profile by create_profile() and writes to profiles table

--PROCEDURE 2: CREATE A NEW PROFILE create_profile()

DELIMITER //
CREATE PROCEDURE create_profile(IN emailid VARCHAR(225), name VARCHAR(225))
BEGIN
	INSERT INTO profiles(profile_name, emailid) VALUES(emailid, name);
END //
DELIMITER ;


--CREATE TABLE 4: profile_history

CREATE TABLE profile_history (
    view_timestamp DATETIME NOT NULL,
    imdb_rank INT NOT NULL,
    emailid VARCHAR(255) NOT NULL,
    profile_name VARCHAR(50) NOT NULL,
    CONSTRAINT prof_his_pk PRIMARY KEY (view_timestamp , profile_name, emailid),
    CONSTRAINT prof_his_fk1 FOREIGN KEY (emailid)
        REFERENCES profiles (emailid)
        ON DELETE CASCADE,
    CONSTRAINT prof_his_fk2 FOREIGN KEY (profile_name)
        REFERENCES profiles (profile_name)
        ON DELETE CASCADE,
    CONSTRAINT prof_his_fk3 FOREIGN KEY (imdb_rank)
        REFERENCES movie (imdb_rank)
        ON DELETE CASCADE
);

--Before adding any data to the profile_history table make sure to execute the below trigger which makes sure no more than 10 history records are present against each user in the profile_history table

--TRIGGER 3: DELETE a record for a profile when history record count goes greater than 10

DELIMITER \\
CREATE TRIGGER profile_history_adding
BEFORE INSERT ON profile_history
FOR EACH ROW
BEGIN
  DECLARE count INT;
  DECLARE oldest TIMESTAMP;
  SELECT view_timestamp FROM profile_history WHERE emailid = NEW.emailid AND profile_name = NEW.profile_name ORDER BY view_timestamp ASC LIMIT 1 INTO oldest;
  SELECT count(*) FROM profile_history WHERE emailid = NEW.emailid AND profile_name = NEW.profile_name group by emailid, profile_name into count;
  IF count >= 10
  THEN
   DELETE FROM profile_history WHERE view_timestamp = oldest;
  END IF;
END\\
DELIMITER ;

--Initially added the data into this table through INSERT statements in profiles-history-insert.sql
--For further adding the data into the profile_history table the below procedure should be called add_profile_history()


--PROCEDURE 3: CREATE RECORD IN profile_history add_profile_history()

DELIMITER //
CREATE PROCEDURE add_profile_history(IN movie_name VARCHAR(100), emailid VARCHAR(225), profile_name VARCHAR(20))
 BEGIN
		DECLARE  prof_name VARCHAR(50) ;
		DECLARE movie_id INT;
		SELECT imdb_rank from movie WHERE Title = movie_name INTO movie_id;

		INSERT INTO profile_history(view_timestamp, imdb_rank, emailid, profile_name) VALUES (CURRENT_TIMESTAMP(), movie_id, emailid, profile_name );
 END //
DELIMITER ;

--CREATE TABLE 5: profile_my_list

CREATE TABLE profile_my_list (
    imdb_rank INT NOT NULL,
    emailid VARCHAR(255) NOT NULL,
    profile_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (profile_name , emailid , imdb_rank),
    FOREIGN KEY (emailid)
        REFERENCES profiles (emailid)
        ON DELETE CASCADE,
    FOREIGN KEY (profile_name)
        REFERENCES profiles (profile_name)
        ON DELETE CASCADE,
    FOREIGN KEY (imdb_rank)
        REFERENCES movie (imdb_rank)
        ON DELETE CASCADE
);

--PROCEDURE 4: ADD WATCH MOVIE TO THE PROFILE LIST add_profile_movie()

DELIMITER //
CREATE PROCEDURE add_profile_movies(IN movie_name VARCHAR(100), emailid VARCHAR(225), name VARCHAR(20))
BEGIN
	DECLARE movie_id INT;
	SELECT imdb_rank from movie WHERE Title = movie_name INTO movie_id;
	INSERT INTO profile_my_list(imdb_rank, emailid, profile_name) VALUES(movie_id, emailid, name);
END //
DELIMITER ;

--CREATE TABLE 6: service_request_info

CREATE TABLE service_request_info (
    complaint_id INTEGER NOT NULL AUTO_INCREMENT,
    service_id INTEGER NOT NULL,
    date_of_complaint DATE,
    complaint_description TEXT,
    CONSTRAINT sr_info_pk PRIMARY KEY (complaint_id),
    CONSTRAINT sr_info_fk FOREIGN KEY (service_id)
        REFERENCES profiles (service_id)
        ON DELETE CASCADE
)  AUTO_INCREMENT=100000;

--PROCEDURE 5: CREATE SERVICE REQUEST
DELIMITER $$
CREATE PROCEDURE createServiceRequest(IN servId INTEGER, IN complaint_describe TEXT)
BEGIN
          	INSERT INTO service_request_info (service_id,date_of_complaint, complaint_description) VALUES (servId, curdate(), complaint_describe);
END $$
DELIMITER ;

--CREATE TABLE 7: service_request_assigned

CREATE TABLE service_request_assigned (
    complaint_id INTEGER NOT NULL,
    complaint_severity VARCHAR(10),
    netflix_service_agent_name VARCHAR(100),
    service_assignment_datetime DATETIME,
    CONSTRAINT sr_assign_pk PRIMARY KEY (COMPLAINT_ID),
    CONSTRAINT sr_assign_fk FOREIGN KEY (complaint_id)
        REFERENCES service_request_info (complaint_id)
);

--CREATE TABLE 8: agent_availability

CREATE TABLE agent_availability (
    agent_name VARCHAR(100) NOT NULL,
    availability BOOLEAN DEFAULT 0,
    CONSTRAINT agent_pk PRIMARY KEY (agent_name)
);
