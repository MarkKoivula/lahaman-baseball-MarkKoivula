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

SELECT DISTINCT year 
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
WHERE c.column_name ilike '%team%' --'playerid'
      and t.table_schema not in ('information_schema', 'pg_catalog')
      and t.table_type = 'BASE TABLE'
ORDER BY t.table_schema;

-- Get Min height --
SELECT namelast,
	   namefirst,
	   height,
	   playerid
FROM public.people
WHERE height IN ( SELECT MIN(height)
				  FROM public.people
				)

SELECT g_all 
       ,app.teamid	   
      ,t.teamid 
	  ,t.franchid 
	  ,t.name
FROM public.appearances app
INNER JOIN public.teams t
ON app.teamid = t.teamid AND 
   app.yearid = t.yearid
WHERE playerid = 'gaedeed01'
---------------------------------------------------------------------------------------------------------
-- 3) Find all players in the database who played at Vanderbilt University. 
--    Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
--    Sort this list in descending order by the total salary earned. 
--    Which Vanderbilt player earned the most money in the majors? -- David Price

-- create temp table of all player salary totals -- 
SELECT playerid, 
       SUM(Salary) as totalSalary
INTO temporary table playersalaries
FROM salaries
--where playerid = 'aardsda01'
GROUP BY playerid
ORDER BY playerid ASC

--drop table playersalaries

SELECT DISTINCT  
        p.namelast 
	   ,p.namefirst
	   ,CONCAT(p.namelast, ', ', p.namefirst) as player_full_name
	   ,p.playerid
	   ,s.schoolid 
	   ,s.schoolname
	   ,COALESCE(ps.totalSalary,0) as totalSalary 
	  
FROM public.people p
  LEFT JOIN public.collegeplaying c
    ON p.playerid = c.playerid
  INNER JOIN schools s 
    ON c.schoolid = s.schoolid
  LEFT JOIN playersalaries ps
   ON p.playerid = ps.playerid
WHERE s.schoolname = 'Vanderbilt University'
ORDER BY totalSalary DESC


-------------------------------------------------------------------------------------------------------
-- 4) Using the fielding table, group players into three groups based on their position: 
--    label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
--    Determine the number of putouts made by each of these three groups in 2016.

-- create the position groupings, put data into temp table
SELECT pos,
       PO,
    CASE WHEN pos = 'OF' THEN 'Outfield'
            WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
			WHEN pos IN ('P','C') THEN 'Battery'
		ELSE 'Unknown'
		END  as PositionGroup
		,yearid
INTO temporary table PositionGroups 	
FROM fielding
WHERE yearid = '2016'

-- select totals by positiongroup, year
SELECT PositionGroup, 
	   SUM(po) as totalPutOuts,
	   yearid
FROM PositionGroups
GROUP BY positiongroup, yearid 
ORDER BY positiongroup ASC;

--drop table PositionGroups
------------------------------------------------------------------------------------------------------------------
-- 5) Find the average number of strikeouts per game by decade since 1920. 
--    Round the numbers you report to 2 decimal places. 
--    Do the same for home runs per game. Do you see any trends? --- it shows an increasing trend for both with each decade

SELECT --yearid, 
      CONCAT(left(cast(yearid as varchar(4)), 3) ,'0') AS decade,
	  ROUND(SUM(g),2) as totalgames,
      ROUND(SUM(COALESCE(SO,0)),2) as totalstrikeouts,
	  CAST(ROUND(SUM(COALESCE(SO,0)),2) / ROUND(SUM(g),2) as decimal(10,2)) AS avgStrikeOutsPerGame
FROM pitching
WHERE yearid >= '1920'
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
-- 	Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. - 
    baseball strike for 50 dya in 1981, resulting in fewer games on average being played during that season. 
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
	 yearid,
			franchid,
			divid,
			name,
	        MIN(W) as MostWins
   FROM teams
   WHERE yearid BETWEEN '1970' and '2016'
   AND WSWin = 'N'
   GROUP BY teamid,
   			yearid,
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
   
   SELECT AVG(G)
    FROM teams
   WHERE yearid = '1982'
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
  
  -- part 2-- 
   	
	DROP TABLE WinWS
	DROP TABLE MaxWins
	
	SELECT teamid as champ, 
		   yearid, 
		   w as champ_w
	INTO temporary table WinWS
	FROM teams 
	WHERE 	(wswin = 'Y') 
	AND (yearid BETWEEN 1970 AND 2016) 
	
	SELECT yearid, 
		   max(w) as maxwins
	INTO temporary table MaxWins
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
     GROUP BY yearid
	
	SELECT 	COUNT(*) AS all_years,
			COUNT(CASE WHEN champ_w = maxwins THEN 'Yes' end) as max_wins_by_champ,
			TO_CHAR((COUNT(CASE WHEN champ_w = maxw THEN 'Yes' end)/(COUNT(*))::real)* 100,'99.99%') as Percent
	FROM 	WinWS 
	LEFT JOIN MaxWins
    USING(yearid)
	
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
SELECT * 
FROM public.awardsmanagers
WHERE awardid ILIKE '%TSN Manager%'

SELECT distinct playerid, awardid, lgid
FROM public.awardsmanagers
WHERE awardid = 'TSN Manager of the Year'
ORDER BY playerid

-- AL league award winners
SELECT playerid, awardid, yearid,lgid
into temp table ALData
FROM public.awardsmanagers
WHERE lgid = 'AL' AND awardid = 'TSN Manager of the Year'

-- NL league award winners
SELECT playerid, awardid, yearid,lgid
into temp table NLData
FROM public.awardsmanagers
WHERE lgid = 'NL' AND awardid = 'TSN Manager of the Year'

--    "leylaji99"
--    "johnsda02"
   
-- drop table ALData
-- DROP table NLData
  
 -- final data --  
	SELECT DISTINCT p.playerid,
			CONCAT(p.namelast, ', ', p.namefirst) as ManagerName,
			al.yearid,
			al.lgid,
			m.teamid,
			t.name
	 FROM ALData al 	
		INNER JOIN people p
			ON al.playerid = p.playerid
		LEFT JOIN managers m
			ON p.playerid = m.playerid 
				AND al.yearid = m.yearid  
				AND al.lgid = m.lgid
		INNER JOIN  teams t
			ON m.teamid = t.teamid
	WHERE p.playerid IN (
						SELECT playerid
						FROM ALData
						INTERSECT
						SELECT playerid
						FROM NLData
						)
UNION
	
	SELECT DISTINCT p.playerid,
			CONCAT(p.namelast, ', ', p.namefirst) as ManagerName,
			nl.yearid,
			nl.lgid,
			m.teamid,
			t.name
	 FROM NLData nl
	INNER JOIN people p
			ON nl.playerid = p.playerid
		LEFT JOIN managers m
			ON p.playerid = m.playerid 
				AND nl.yearid = m.yearid  
				AND nl.lgid = m.lgid
		INNER JOIN  teams t
			ON m.teamid = t.teamid 
				AND m.lgid = t.lgid 
				AND m.yearid = t.yearid
	WHERE p.playerid IN (
						SELECT playerid
						FROM ALData
						INTERSECT
						SELECT playerid
						FROM NLData
						)
	 ORDER BY managername, yearid ASC
	
---------------------------------------------------------------------------------------------------------------------------------------------------
--10).Analyze all the colleges in the state of Tennessee. Which college has had the most success in the major leagues. 
--     Use whatever metric for success you like - number of players, number of games, salaries, world series wins, etc. 
-- Based on nuber of players active in the majors by school, University of Tennessee has the largest number of players.
   
   SELECT schoolid
   		  ,schoolname 
   INTO temp table TNColleges
   FROM schools
   WHERE schoolstate = 'TN'
   ORDER BY schoolname ASC
   
   DROP TABLE TNColleges
   --SELECT * FROM TNColleges
   
   
   
SELECT playerid, 
COUNT(*) as AllStarsCnt
INTO temporary table AllStarGames
FROM public.allstarfull
GROUP BY playerid
ORDER BY 2 DESC

select * from AllStarGames
 
--DROP TABLE AllStarGames
   
   SELECT count(WSWin) as WSWinCnt, 
   		  teamid, 
		  name
		  rank
   INTO temp table TotalWSWins
   FROM teams 
   GROUP BY teamid, name
   ORDER BY rank desc
   
   select * from TotalWSWins
   order by 1 DESC
   
   drop table TotalWSWins
   

SELECT
	s.schoolname, 
	RANK () OVER ( 
		ORDER BY COUNT(p.playerid) DESC
	) ranking 
FROM public.people p
  
  INNER JOIN public.collegeplaying c
    ON p.playerid = c.playerid
	
  INNER JOIN public.appearances a
  	ON p.playerid = a.playerid

  INNER JOIN teams t
   ON a.teamid = a.teamid 
   	and a.lgid = t.lgid 
	and a.yearid = t.yearid
	
  INNER JOIN TNColleges s 
    ON c.schoolid = s.schoolid

GROUP BY s.schoolname
 


------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   11) --Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. 
    -- As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
   
     
-- SELECT t.yearid
-- 	   ,t.teamid
-- 	   ,t.name
-- 	   ,t.W as Wins
-- 	   ,SUM(s.salary) as TotalSalary 
-- FROM teams t
-- INNER JOIN salaries s
-- 	ON t.teamid = s.teamid 
-- 	  and t.yearid = s.yearid
-- --WHERE t.teamid = 'OAK'
-- GROUP BY t.yearid
-- 	   ,t.teamid
-- 	   ,t.name
-- 	   ,t.W
-- ORDER BY t.w DESC
   
 --CREATE EXTENSION tablefunc;
   
    SELECT 
   		  t.yearid,
   	      t.teamid,
          CAST(corr(a.Wins, a.TotalSalary) as DECIMAL(10,4)) as Correlation 
    FROM(
		SELECT t.yearid
			   ,t.teamid
			   ,t.name
			   ,cast(t.W as float) as Wins
			   ,SUM(cast(s.salary as float)) as TotalSalary 		
		FROM teams t
		INNER JOIN salaries s
			ON t.teamid = s.teamid 
			  and t.yearid = s.yearid
		GROUP BY  t.yearid
			     ,t.teamid
			     ,t.name
			     ,t.W
	   ) AS a
     
    INNER JOIN teams t
	  ON a.teamid = t.teamid 
	  	 AND a.yearid = a.yearid
		
	  INNER JOIN salaries s
			ON t.teamid = s.teamid 
			  AND t.yearid = s.yearid   
   WHERE t.yearid >= 2000
   
   GROUP BY t.yearid,
   	        t.teamid
			order by 3 DESC
			
 --------------------------------------------------------------------------------------------------------------------------------------------------------  
   12) --In this question, you will explore the connection between number of wins and attendance.
    
    -- Does there appear to be any correlation between attendance at home games and number of wins? 
     --Do teams that win the world series see a boost in attendance the following year? 
     --What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
    
	SELECT 
   		  t.yearid,
   	      t.teamid,
          CAST(corr(a.Wins, a.TotalHomeAttendance) as DECIMAL(10,4)) as Correlation 
    FROM(
        SELECT t.yearid
			   ,t.teamid
			   ,t.name
			   ,cast(t.W as float) as Wins
			   ,SUM(cast(attendance as float)) as TotalHomeAttendance 		
		FROM teams t
		INNER JOIN salaries s
			ON t.teamid = s.teamid 
			  and t.yearid = s.yearid
	  	GROUP BY  t.yearid
			     ,t.teamid
			     ,t.name
			     ,t.W 
     ) AS a
     
    INNER JOIN teams t
	     ON a.teamid = t.teamid 
	  	 AND a.yearid = a.yearid		
	INNER JOIN salaries s
		ON t.teamid = s.teamid 
		AND t.yearid = s.yearid   
   WHERE t.yearid >= 2000
   GROUP BY t.yearid,
   	        t.teamid
	ORDER BY 1 DESC
	
  -- part 2--
	select * from teams
	where teamid in (SELECT teamid from teams where WSWin = 'Y' )
	and yearid > 2000
	
	TOR
	STL
	PHI
	PIT
	OAK
	
	select yearid, teamid, attendance, wswin
	into temp table Winner
	from teams
    where teamid in ('PHI')
	and yearid =2009
	and wswin = 'N'
	
	
	select yearid, teamid, attendance, wswin
	into temp table Lost
	from teams
    where teamid in ('PHI')
	and yearid >=2000
	and wswin = 'Y'
	
	
	select w.teamid, w.yearid, w.attendance as AttendanceW, l.yearid, l.attendance as AttendanceL
	from Winner w
	left join Lost l
		on w.Teamid = l.teamid
	
	drop table Winner
	drop table Lost
	
	SELECT * FROM CROSSTAB(
						  'SELECT
								*
							FROM teams
							ORDER BY 1,2'
						  ) 
AS summary(
	store VARCHAR, 
    "2016" INT, 
    "2017" INT, 
    "2018" INT
    );
	