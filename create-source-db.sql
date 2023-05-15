create table test1 (
id varchar(10) not null primary key,
name varchar(10)
);

create table test2 (
id varchar(10) not null primary key,
name varchar(10)
);

-- without publication postgres can't send event change
create publication kafkaconnectpublication for table test1;
alter publication kafkaconnectpublication add table test2;

insert into test1 values ('1', 'test for 1');

insert into test2 values ('1', 'test for 1');
