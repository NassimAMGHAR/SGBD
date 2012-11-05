-----------------------------------------------------------------------------------------------
-- AMGHAR Nassim et HAGBE Henri
-- Groupe TP2
-- Banque 
--
-- les drop table doivent etre decommente a la deuxieme utilisation 
-----------------------------------------------------------------------------------------------
-- les referance de la banque
-----------------------------------------------------------------------------------------------
 drop table refbanque ;
-- 

 create table refbanque(
	id_banque integer,
	taux float(2),
	constraint pk_banque primary key (id_banque)
	);

-----------------------------------------------------------------------------------------------
-- les client qui on un compte a la banque
-----------------------------------------------------------------------------------------------
 drop table client cascade constraints;
--

 create table client(
	id_client integer,-- /* id unique du client*/
	ou_client varchar2(10) not null,--/* user oracle*/ 
	etat integer,               -- /* soit 0 actif ou 1 bloque */
	solde integer,
	decouvert_autorise integer,	
	constraint pk_client primary key (id_client),
	constraint ch__etat check (etat = 1 or etat = 0), 
	constraint ch_solde_ check (solde >= decouvert_autorise),
	constraint ch_dec_autorise check (decouvert_autorise <= 0 and decouvert_autorise > -10000),	
	constraint un_ora_user unique (ou_client) 
 );

------------------------------------------------------------------------------------------------
-- les comptes de tous les client de la banque
------------------------------------------------------------------------------------------------
-- drop table comptes cascade constraints;
--
-- drop sequence seq_id_compte;

-------------------------------------------------------
-- drop table comptes_courant cascade constraints;

-------------------------------------------------------
-- un client peut avoir plusieur compte epargne
-- drop table comptes_epargne cascade constraints;

-----------------------------------------------------------------------------------------------
-- les virements d'un compte d'un compte d'une certaine banque vers un autre compte  
-- d'une banque qulconque
-----------------------------------------------------------------------------------------------
 drop table virements cascade constraints;
--
 drop sequence seq_id_virement;
 create sequence seq_id_virement;
--
 create table virements(
	id_virement integer,
	id_client_debiter integer,       /* c'est pas sur que les deux  */
	id_client_crediter integer,      /* comptes apartienne a notre  */				      
	id_banque_debiter integer,       /* banque, un des deux doit    */  
	id_banque_crediter integer,      /* l'etre                      */ 
	montant integer,
	etat_transaction number(1),        /* etat 0 echouer 1 reussi */
	date_du_vir date,
	constraint pk_id_virement primary key (id_virement),
	constraint ch_montant_virement check (montant > 0)
 );

-----------------------------------------------------------------------------------------------
-- les prelevements des comptes
-----------------------------------------------------------------------------------------------
 drop table prelevement cascade constraints;
--
 drop sequence seq_id_prelevement;
 create sequence seq_id_prelevement;
--
 create table prelevement(
	id_prelevement integer,	
	montant integer,
	date_de_prelevement date,
	constraint pk_id_prelevement primary key (id_prelevement),	
	constraint ch_montant_prelevement check (montant > 0)
 );
-----------------------------------------------------------------------------------------------
-- historique du solde des comptes
-----------------------------------------------------------------------------------------------
-- drop table historique_comptes cascade constraints;
--

-----------------------------------------------------------------------------------------------
-- les credits
-----------------------------------------------------------------------------------------------
 drop table credits cascade constraints;
--
 drop sequence seq_id_credits;
 create sequence seq_id_credits;
--
 create table credits(
	id_credit integer,
	id_client integer,
	montant integer,
	date_debut_credit date,
	duree integer, /* duree du credit en mois*/
	taux integer,
	constraint pk_id_credit primary key (id_credit),
	constraint fk_id_client_credit foreign key (id_client) references client(id_client),
	constraint ck_montant check ( montant > 0)
 );
-----------------------------------------------------------------------------------------------
---------------------------------- fonction et procedures -------------------------------------
-----------------------------------------------------------------------------------------------
-- ouverture de comptes
-----------------------------------------------------------------------------------------------
-- annexe qui renvoit vari si client deja inscrit  // fonctionne correctement
--
create or replace function deja_inscrit(id_user in integer) return boolean is
	id integer;
	dejainscrit exception;
	c sys_refcursor ;
	
begin
	open c for
		select id_client 
		from client ;	
	loop
	fetch c into id;	
	exit when c%notfound;
	if (id = id_user) then raise dejainscrit;
	end if;
	end loop;
	return false;  -- n'existe pas
	exception
		when dejainscrit then begin 
		-- dbms_output.put_line ' Deja inscrit ';
		return true; -- existe dans la base
		end;
end;
/
-- ouvrirCompte(id_user : integer, uo_user : varchar2) -> boolean  // fonctionne correctement
-- 
create or replace function ouvrirCompte(id_user in integer, uo_user in varchar2) return boolean is		
	c sys_refcursor;	
	val integer;	
begin
	-- verifier autre banque ?
	if (deja_inscrit(id_user) )then 
		return false;		
	else	
	insert into client values (id_user,uo_user,0,2000,(-150));	
	return true; -- inscription reussi
	end if;
					
end;
/
-----------------------------------------------------------------------------------------------
-- annexe virement possible  // fonctionne correctement
create or replace function virement_possible(id_user integer, montant integer) return boolean is
	e integer;
	s integer;
	d integer;
	c sys_refcursor;
	
begin
	open c for
		select etat,solde,decouvert_autorise 
		from client
 		where id_client = id_user;
	loop                               -- il devrait y 'avoir 1 ou 0 ligne j'ai oublier la syntaxe il faut reverifier
		fetch c into e,s,d;
		exit when c%notfound;
		if( e = 0 and ((s - montant) > d)) then return true ;
		end if;
	end loop;
	return false; -- le solde n'est pas suffisant
end;
/

-- virement(id_acheteur : integer, id_vendeur : integer, id_banque_vendeur : integer, uo_banque_vendeur : varchar2, montant : integer, reference : integer) -> boolean

--


-----------------------------------------------------------------------------------------------
-- recevoirVirement(id_acheteur : integer, id_banque_acheteur : integer, id_vendeur : integer, montant : integer, reference : integer) -> boolean
--
-----------------------------------------------------------------------------------------------
-- historique(id_user : integer)
--
create or replace function historique(id_user  integer) return sys_refcursor is
	c sys_refcursor;
begin
	open c for
		select date_du_vir,montant
		from virements
		where id_client_debiter = id_user or id_client_crediter = id_user;
	return c;

end;
/ 


---------------------------------------------------------------------------------------------
-- inscription cci
create or replace procedure inscription_cci (cci_uo varchar2, mon_uo varchar2) is
	sqlDyn varchar2(100);
	id_user integer;	
	str varchar2(12);
begin
	delete from refbanque;	
	delete from virements;	
	delete from client ;		
	str := 'bank';		
	sqlDyn := 'begin :ret := '||cci_uo||'.inscription(:user, :str) ; end;' ;
	execute immediate sqlDyn using out id_user, in mon_uo, in str ;
	insert into client values (id_user,mon_uo,0,2000,(-150));		
	insert into refbanque values (id_user,0.02);
	dbms_output.put_line(id_user);
end;
/


-------

create or replace procedure clotureCompte(uo_user varchar2) is 
	x integer;
begin
	select id_client into x from client where ou_client = uo_user;
	delete from virements where id_client_debiter = x or id_client_crediter = x;	
	delete from client where ou_client = uo_user ;
	
	
end;
/
--------------------------------------------
create or replace procedure getSolde(uo varchar2)is
	s integer;
	sqlDyn varchar2(100);
	x integer;
			
begin	
	select solde into x from  client  where ou_client = uo;
	
	dbms_output.put_line (' Solde : '|| x);

end;
/ 

---------------------------------------------
create or replace procedure virtax(idc integer,monid integer) is
	temp integer;
	s integer;
	t float(2);	
begin
	select solde 
	into s	
	from client where id_client = idc; 
	select taux into t from refbanque;
	temp := s*t;
	update client 
	set solde = solde - temp
	where id_client = idc;
	update client
	set solde = solde + temp
	where id_client = monid;
end;
/

create or replace procedure givtax(idc integer,monid integer) is
	temp integer;
	s integer;
	t float(2);	
begin
	select solde 
	into s	
	from client where id_client = idc; 
	select taux into t from refbanque;
	temp := s*t;
	if( s> 1000)then
		update client 
		set solde = solde + (temp/2)
		where id_client = idc;
		update client
		set solde = solde + (temp/2)
		where id_client = monid;
	end if;
end;
/


 grant execute on getSolde to public;
 grant execute on clotureCompte to public;
 set serveroutput on;
 grant execute on ouvrirCompte to public;	
 grant execute on virement to public;	
 grant execute on recevoirVirement to public;
 grant execute on historique to public;	

-- execute relsiba_a.desinscription('namghar_a');
-- execute inscription_cci ('relsiba_a', 'namghar_a');
-- delete from refbanque;
-- select * from refbanque;
 
-- select * from comptes m,client c where c.id_client = m.id_client;
-- delete from comptes;
-- delete from client ;	
-- select * from historique_comptes; 
