--1) What range of years does the provided database cover? -- 1871 to 2016
-- performs search of all information_schema tables for cols named 'year'
-- select t.table_schema,
--        t.table_name
-- from information_schema.tables t
-- inner join information_schema.columns c on c.table_name = t.table_name 
--                                 and c.table_schema = t.table_schema
-- where c.column_name ilike= '%name%'
--       and t.table_schema not in ('information_schema', 'pg_catalog')
--       and t.table_type = 'BASE TABLE'
-- order by t.table_schema;

SELECT distinct year 
FROM public.homegames
ORDER BY year ASC -- 1871 to 2016

--(Also found dates match what is described in the online data dictionary)
-------------------------------------------------------------------------------------------------
-- 2) Find the name and height of the shortest player in the database. -- Eddie Gaedel, 43 inches
--    How many games did he play in? --1 game, 1951
--    What is the name of the team for which he played? St. Louis Browns
   
SELECT t.table_schema,
       t.table_name
FROM information_schema.tables t
INNER JOIN information_schema.columns c 
   ON c.table_name = t.table_name 
      and c.table_schema = t.table_schema
WHERE c.column_name = 'playerid'
      and t.table_schema not in ('information_schema', 'pg_catalog')
      and t.table_type = 'BASE TABLE'
ORDER BY t.table_schema;

-- Get Min height --
select namelast,
	   namefirst,
	   height,
	   playerid
from public.people
where height in ( select MIN(height)from public.people )

select g_all 
       ,app.teamid	   
      ,t.teamid 
	  ,t.franchid 
	  ,t.name
from public.appearances app
inner join public.teams t
on app.teamid = t.teamid and 
   app.yearid = t.yearid
where playerid = 'gaedeed01'
---------------------------------------------------------------------------------------------------------
-- 3) Find all players in the database who played at Vanderbilt University. 
--    Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
--    Sort this list in descending order by the total salary earned. 
--    Which Vanderbilt player earned the most money in the majors? -- David Price

-- create temp table of all player salary totals -- 
select playerid, 
       SUM(Salary) as totalSalary
into temporary table playersalaries
from salaries
--where playerid = 'aardsda01'
GROUP BY playerid
order by playerid asc

--drop table playersalaries

select distinct 
        p.namelast 
	   ,p.namefirst
	   ,CONCAT(p.namelast, ', ', p.namefirst) as player_full_name
	   ,p.playerid
	   ,s.schoolid 
	   ,s.schoolname
	   ,coalesce(ps.totalSalary,0) as totalSalary 
	  
from public.people p
  left join public.collegeplaying c
    on p.playerid = c.playerid
  inner join schools s 
    on c.schoolid = s.schoolid
  left join playersalaries ps
   on p.playerid = ps.playerid
where s.schoolname = 'Vanderbilt University'
order by totalSalary desc
-------------------------------------------------------------------------------------------------------
-- 4) Using the fielding table, group players into three groups based on their position: 
--    label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
--    Determine the number of putouts made by each of these three groups in 2016.

-- create the position groupings, put data into temp table
select pos,
       PO,
    CASE WHEN pos = 'OF' THEN 'Outfield'
            WHEN pos IN ('SS','1B','2B','3B') then 'Infield'
			WHEN pos IN ('P','C') then 'Battery'
		else 'Unknown'
		END  as PositionGroup
		,yearid
into temporary table PositionGroups 	
from fielding
where yearid = '2016'

-- select totals by positiongroup, year
select PositionGroup, 
	   SUM(po) as totalPutOuts,
	   yearid
from PositionGroups
group by positiongroup, yearid 
order by positiongroup ASC;

--drop table PositionGroups
------------------------------------------------------------------------------------------------------------------
-- 5) Find the average number of strikeouts per game by decade since 1920. 
--    Round the numbers you report to 2 decimal places. 
--    Do the same for home runs per game. Do you see any trends? --- it shows an increasing trend for both with each decade

SELECT --yearid, 
      CONCAT(left(cast(yearid as varchar(4)), 3) ,'0') as decade,
	  ROUND(SUM(g),2) as totalgames,
      ROUND(SUM(COALESCE(SO,0)),2) as totalstrikeouts,
	  CAST(ROUND(SUM(COALESCE(SO,0)),2) / ROUND(SUM(g),2) as decimal(10,2)) as avgStrikeOutsPerGame
FROM pitching
where yearid >= '1920'
GROUP BY CONCAT(left(cast(yearid as varchar(4)), 3) ,'0')
ORDER BY CONCAT(left(cast(yearid as varchar(4)), 3) ,'0') ASC

-- select SUM(g) from pitching
-- where yearid = '1920'
-- CONCAT(left(cast(yearid as varchar(4)), 3) ,'0') = '1920' --total games

-- select ROUND(SUM(COALESCE(SO,0)),2) from pitching
-- where yearid = '1920' -- total strikeouts


----------------------------------------------------------------------------------------------------------------------
-- 6) Find the player who had the most success stealing bases in 2016, 
--    where success is measured as the percentage of stolen base attempts which are successful. 
--   (A stolen base attempt results either in a stolen base or being caught stealing.) 
--      Consider only players who attempted at least 20 stolen bases.
	 
	 SELECT b.playerid ,
	        p.namelast,
			p.namefirst,
			CONCAT(p.namelast, ', ', p.namefirst) as playername,
          	SUM(SB) + SUM(CS) as totalAttempts,
			SUM(CS) as CaughtStealing,			
		  CASE when SUM(SB) + SUM(CS) <=0 THEN 0 ELSE SUM(SB) END as SuccessSB,
          CAST(CAST(SUM(SB) as decimal(10,2)) / CAST(SUM(SB) + SUM(CS) as decimal(5,2))* 100 as decimal(10,2)) as PercentSuccess
	 FROM batting as b
	 LEFT JOIN people as p
	  ON b.playerid = p.playerid
	 WHERE b.yearid = '2016' 
	-- and playerid = 'maybica01'
	 GROUP BY b.playerid ,
	          p.namelast,
			  p.namefirst,
			 CONCAT(p.namelast, ', ', p.namefirst)
	 HAVING SUM(SB) + SUM(CS) > 20
	 ORDER BY CAST(CAST(SUM(SB) as decimal(10,2)) / CAST(SUM(SB) + SUM(CS) as decimal(5,2))* 100 as decimal(10,2)) DESC;
	 
	----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? Seatlle Mariners, 116 Wins 
--     What is the smallest number of wins for a team that did win the world series? - Toronto Blue Jays, 37 Wins
-- 	Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. - baseball strike in 1981, resulting in fewer games on average being played 
-- in the season. TOR played in 106 games that year, one less than the average 107.
-- 	Then redo your query, excluding the problem year. 
-- 	How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
-- 	What percentage of the time?
	 
	 -- most wins -- 
	 SELECT teamid,
			franchid,
			divid,
			name,
	        MAX(W) as MostWins
   FROM teams
   WHERE yearid BETWEEN '1970' and '2016'
   AND WSWin = 'N'
   GROUP BY teamid,
			franchid,
			divid,
			name
   ORDER BY  MAX(W) DESC
  
  -- least wins--
	 SELECT teamid,
			franchid,
			divid,
			name,
	        MIN(W) as MostWins
   FROM teams
   WHERE yearid BETWEEN '1970' and '2016'
   AND WSWin = 'N'
   GROUP BY teamid,
			franchid,
			divid,
			name
   ORDER BY  MIN(W) ASC

 -- baseball strike in 1981, fewer games played... 
   SELECT W, G, *
   FROM teams
   WHERE yearid = '1981'
   AND WSWin = 'N'
   --and teamid = 'TOR'  
   ORDER BY  G ASC
   -- average games played in 1981 was 107 games
   SELECT AVG(G)
    FROM teams
   WHERE yearid = '1981'
   AND WSWin = 'N'
   
   -- 1981--
   SELECT     
            teamid,
			name,
	        MIN(W) as MinWins
   FROM teams
   WHERE yearid BETWEEN '1970' and '2016' and yearid != '1981'
   AND WSWin = 'N'
   GROUP BY  teamid,
			 name
   ORDER BY  MIN(W) ASC
   
   SELECT yearid,
          MIN(teamid),
	      MAX(W) as Wins
   FROM teams
   WHERE yearid BETWEEN '1970' and '2016'
   GROUP BY yearid
   order by yearid ASC
   
   select yearid, teamid, W, WSWin
   from teams
   WHERE yearid BETWEEN '1970' and '1974'
    AND WSWin = 'Y'
   ORDER by yearid ASC
   
    select yearid, Max(teamid), MAX(W)
   from teams
   WHERE yearid BETWEEN '1970' and '1974'
    AND WSWin = 'Y'
	GROUP BY yearid
   ORDER by yearid ASC
   
   select yearid, teamid, W, WSWin
   from teams
   WHERE yearid BETWEEN '1970' and '1974'
   -- AND WSWin = 'y'
	--GROUP BY yearid
   ORDER by yearid, W DESC
   ----------------------------------------------------------------------------------------------------------------------------------------------
  -- 8. Using the attendance figures from the homegames table, 
 -- find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). 
  --Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
-- select * from homegames
-- select * from teams
  
  -- Top 5 avg attendance --
   SELECT t.teamid, 
   	      t.name,
		  COALESCE(t.park,'No park listed') as parkname,
		  CASE WHEN SUM(h.games) <=0 THEN 0 
		  ELSE CAST(SUM(h.attendance/h.games) as float)		  
		  END as average_attendance
   FROM homegames h
   LEFT JOIN teams t
   ON h.team = t.teamid and h.year = t.yearid
   WHERE h.games >= 10
   AND h.year = '2016'
   GROUP BY t.teamid, 
   	        t.name,
		    t.park
   ORDER BY 4 DESC
   LIMIT 5;
   
-- Lowest 5 avg attendance -- 
   SELECT t.teamid, 
   	      t.name,
		  COALESCE(t.park,'No park listed') as parkname,
		  CASE WHEN SUM(h.games) <=0 THEN 0 
		  ELSE CAST(SUM(h.attendance/h.games) as float)		  
		  END as average_attendance
   FROM homegames h
   LEFT JOIN teams t
   ON h.team = t.teamid and h.year = t.yearid
   WHERE h.games >= 10
   AND h.year = '2016'
   GROUP BY t.teamid, 
   	        t.name,
		    t.park
   ORDER BY 4 ASC
   LIMIT 5;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  9) Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? -- Bobby Cox 
-- Give their full name and the teams that they were managing when they won the award.
select * from public.awardsmanagers
where awardid ilike '%TSN Manager%'


select distinct playerid, awardid, lgid
from public.awardsmanagers
where awardid = 'TSN Manager of the Year'
--and  playerid = 'leylaji99' 
and playerid = 'johnsda02'
order by playerid


select playerid, awardid, yearid,lgid
into temp table ALData
from public.awardsmanagers
where lgid = 'AL' 
      and awardid = 'TSN Manager of the Year'

select playerid, awardid, yearid,lgid
into temp table NLData
from public.awardsmanagers
where lgid = 'NL' 
and awardid = 'TSN Manager of the Year'


-- drop table ALData
-- DROP table NLData
   
   
  -- final select -- 
 SELECT DISTINCT p.playerid,
 		CONCAT(p.namelast, ', ', p.namefirst) as ManagerName,
 		al.awardid, 
		al.lgid,
		al.yearid as ALYear, 
		nl.playerid, 
		nl.awardid	,
		nl.yearid as NLYear,
		nl.lgid
 FROM ALData al
 	INNER JOIN NLData nl
 		ON al.playerid = nl.playerid 
 	INNER JOIN people p
  		ON al.playerid = p.playerid
 ORDER BY 2
 
  SELECT * FROM ALData al
  WHERE al.playerid = 'leylaji99'
  UNION 
  SELECT * FROM NLData nl
  WHERE nl.playerid = 'leylaji99'
 
 
 -- Get team, league for each manager when won award(s).
SELECT *
FROM managers 
WHERE playerid = 'leylaji99' and lgid = 'AL' and yearid = '1997'

select * from teams
where playerid = 'leylaji99' and lgid = 'AL'


--WHERE playerid = 'johnsda02'
   