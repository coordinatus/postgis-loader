-- polygon
WITH g AS (SELECT 'POLYGON((132 10,119 23,85 35,68 29,66 28,49 42,32 56,22 64,32 110,40 119,36 150,
57 158,75 171,92 182,114 184,132 186,146 178,176 184,179 162,184 141,190 122,
190 100,185 79,186 56,186 52,178 34,168 18,147 13,132 10))'::geometry As geom)
, gs AS (SELECT ST_Area(geom) As full_area, ST_Subdivide(geom,10) As geom FROM g)
SELECT '1' As rn, full_area::numeric(10,3) = SUM(ST_Area(gs.geom))::numeric(10,3), COUNT(gs.geom) As num_pieces, MAX(ST_NPoints(gs.geom)) As max_vert
FROM gs
GROUP BY gs.full_area;

-- linestring
WITH g AS (SELECT ST_Segmentize('LINESTRING(0 0, 10 10, 15 15)'::geography,150000)::geometry As geom)
, gs AS (SELECT ST_Length(geom) As m, ST_Subdivide(geom,8) As geom FROM g)
SELECT '2' As rn, m::numeric(10,3) = SUM(ST_Length(gs.geom))::numeric(10,3), COUNT(gs.geom) As num_pieces, MAX(ST_NPoints(gs.geom)) As max_vert
FROM gs
GROUP BY gs.m;

-- multipolygon
WITH g AS (SELECT 'POLYGON((132 10,119 23,85 35,68 29,66 28,49 42,32 56,22 64,32 110,40 119,36 150,
57 158,75 171,92 182,114 184,132 186,146 178,176 184,179 162,184 141,190 122,
190 100,185 79,186 56,186 52,178 34,168 18,147 13,132 10))'::geometry As geom)
, gs AS (SELECT ST_Area(ST_Union(g.geom, ST_Translate(g.geom,300,10) )) As full_area, ST_Subdivide(ST_Union(g.geom, ST_Translate(g.geom,300,10) ), 10) As geom FROM g)
SELECT '3' As rn, full_area::numeric(10,3) = SUM(ST_Area(gs.geom))::numeric(10,3), COUNT(gs.geom) As num_pieces, MAX(ST_NPoints(gs.geom)) As max_vert
FROM gs
GROUP BY gs.full_area;

SELECT '#3135', st_astext(ST_Subdivide(ST_GeomFromText('POLYGON((1 2,1 2,1 2,1 2))'), 2));
SELECT '#3522', ST_AsText(ST_Subdivide(ST_GeomFromText('POINT(1 1)',4326),10));

with inverted_geom as (
    select ST_Difference(
               ST_Expand('SRID=3857;POINT(0 0)' :: geometry, 20000000),
               ST_Buffer(
                   'SRID=3857;POINT(0 0)' :: geometry,
                   1,
                   1000
               )
           ) as geom
)
select '#3744', ST_Area(ST_Simplify(ST_Union(geom), 2))::numeric
from (
         select ST_Subdivide(geom) geom
         from inverted_geom
     ) z;

\i regress_big_polygon.sql

create table big_polygon_sliced as (
	select ST_Subdivide(geom) As geom FROM big_polygon
);

-- regression big polygon
SELECT '4' As rn,
	(select ST_Area(geom)::numeric(12,1) from big_polygon) as orig_area,
	SUM(ST_Area(gs.geom))::numeric(12,1) as pieces_area,
	COUNT(gs.geom) as num_pieces,
	MAX(ST_NPoints(gs.geom)) as max_vert
FROM big_polygon_sliced gs;

drop table big_polygon;
drop table big_polygon_sliced;

select '#4211', (select sum(ST_Area(geom))::numeric(12,11) from ST_Subdivide('MULTIPOLYGON(((-88.2059 41.7325,-88.2060 41.7244,-88.1959 41.7241,-88.1959 41.7326,-88.2059 41.7325),(-88.1997 41.7289,-88.1996 41.7285,-88.1990 41.7285,-88.1990 41.7289,-88.1997 41.7289)))') geom );

select '#4217', (select sum(ST_Area(geom))::numeric(12,11) from ST_Subdivide('0103000000140000006500000002773098F45057C024E3F62915844640CDE0FEEEF95057C024E3F62915844640CDE0FEEEF95057C0B9B693D71F844640974ACD45FF5057C0B9B693D71F844640974ACD45FF5057C024E3F6291584464062B49B9C045157C024E3F62915844640F787384A0F5157C024E3F62915844640F787384A0F5157C08F0F5A7C0A844640C1F106A1145157C08F0F5A7C0A844640C1F106A1145157C024E3F629158446408C5BD5F7195157C024E3F629158446408C5BD5F7195157C08F0F5A7C0A84464056C5A34E1F5157C08F0F5A7C0A84464056C5A34E1F5157C078316AE03F8446408C5BD5F7195157C078316AE03F8446408C5BD5F7195157C00D05078E4A84464056C5A34E1F5157C00D05078E4A84464056C5A34E1F5157C0A2D8A33B55844640212F72A5245157C0A2D8A33B55844640212F72A5245157C038AC40E95F84464056C5A34E1F5157C038AC40E95F8446408C5BD5F7195157C038AC40E95F8446408C5BD5F7195157C0CD7FDD966A84464056C5A34E1F5157C0CD7FDD966A84464056C5A34E1F5157C062537A44758446408C5BD5F7195157C062537A44758446408C5BD5F7195157C08CFAB39F8A8446402C1E6AF3095157C08CFAB39F8A8446402C1E6AF3095157C0F72617F27F844640CDE0FEEEF95057C0F72617F27F844640CDE0FEEEF95057C08CFAB39F8A844640D8CFF63CDF5057C08CFAB39F8A844640D8CFF63CDF5057C0F72617F27F8446400E6628E6D95057C0F72617F27F8446400E6628E6D95057C08CFAB39F8A84464090707BD4995057C08CFAB39F8A84464090707BD4995057C0CD7FDD966A844640C506AD7D945057C0CD7FDD966A844640C506AD7D945057C062537A4475844640FA9CDE268F5057C062537A4475844640FA9CDE268F5057C08CFAB39F8A844640303310D0895057C08CFAB39F8A844640303310D0895057C0F72617F27F84464065C94179845057C0F72617F27F84464065C94179845057C08CFAB39F8A8446403B22081E6F5057C08CFAB39F8A8446403B22081E6F5057C0F72617F27F844640A64E6B70645057C0F72617F27F844640A64E6B70645057C08CFAB39F8A8446404711006C545057C08CFAB39F8A8446404711006C545057C062537A44758446407CA731154F5057C062537A44758446407CA731154F5057C0CD7FDD966A8446404711006C545057C0CD7FDD966A844640A64E6B70645057C0CD7FDD966A844640A64E6B70645057C038AC40E95F844640DCE49C195F5057C038AC40E95F844640DCE49C195F5057C0A2D8A33B55844640A64E6B70645057C0A2D8A33B55844640A64E6B70645057C078316AE03F8446403B22081E6F5057C078316AE03F8446403B22081E6F5057C00D05078E4A84464065C94179845057C00D05078E4A84464065C94179845057C078316AE03F844640FA9CDE268F5057C078316AE03F844640FA9CDE268F5057C00D05078E4A844640C506AD7D945057C00D05078E4A844640C506AD7D945057C0A2D8A33B5584464090707BD4995057C0A2D8A33B5584464090707BD4995057C038AC40E95F84464025441882A45057C038AC40E95F84464025441882A45057C0CD7FDD966A8446405ADA492B9F5057C0CD7FDD966A8446405ADA492B9F5057C0F72617F27F84464079928B38CF5057C0F72617F27F84464079928B38CF5057C0B9B693D71F844640AE28BDE1C95057C0B9B693D71F844640AE28BDE1C95057C024E3F6291584464079928B38CF5057C024E3F6291584464079928B38CF5057C08F0F5A7C0A84464043FC598FD45057C08F0F5A7C0A84464043FC598FD45057C0D0948373EA8346400E6628E6D95057C0D0948373EA834640D8CFF63CDF5057C0D0948373EA834640D8CFF63CDF5057C0A6ED4918D5834640A339C593E45057C0A6ED4918D58346406DA393EAE95057C0A6ED4918D58346406DA393EAE95057C03BC1E6C5DF834640A339C593E45057C03BC1E6C5DF834640A339C593E45057C0D0948373EA83464002773098F45057C0D0948373EA83464002773098F45057C03BC1E6C5DF834640CDE0FEEEF95057C03BC1E6C5DF834640CDE0FEEEF95057C0D0948373EA83464062B49B9C045157C0D0948373EA83464062B49B9C045157C065682021F58346402C1E6AF3095157C065682021F58346402C1E6AF3095157C0FA3BBDCEFF834640CDE0FEEEF95057C0FA3BBDCEFF83464002773098F45057C0FA3BBDCEFF83464002773098F45057C024E3F629158446400500000065C94179845057C00D05078E4A84464065C94179845057C0A2D8A33B55844640303310D0895057C0A2D8A33B55844640303310D0895057C00D05078E4A84464065C94179845057C00D05078E4A8446400500000002773098F45057C0A2D8A33B55844640CDE0FEEEF95057C0A2D8A33B55844640CDE0FEEEF95057C00D05078E4A84464002773098F45057C00D05078E4A84464002773098F45057C0A2D8A33B558446400500000002773098F45057C0A2D8A33B55844640380D6241EF5057C0A2D8A33B55844640380D6241EF5057C038AC40E95F84464002773098F45057C038AC40E95F84464002773098F45057C0A2D8A33B5584464007000000A339C593E45057C0A2D8A33B55844640A339C593E45057C00D05078E4A8446400E6628E6D95057C00D05078E4A8446400E6628E6D95057C078316AE03F84464043FC598FD45057C078316AE03F84464043FC598FD45057C0A2D8A33B55844640A339C593E45057C0A2D8A33B558446400D00000062B49B9C045157C078316AE03F84464062B49B9C045157C0A2D8A33B558446402C1E6AF3095157C0A2D8A33B558446402C1E6AF3095157C038AC40E95F84464062B49B9C045157C038AC40E95F84464062B49B9C045157C0CD7FDD966A8446402C1E6AF3095157C0CD7FDD966A844640C1F106A1145157C0CD7FDD966A844640C1F106A1145157C0E35DCD3235844640F787384A0F5157C0E35DCD3235844640F787384A0F5157C078316AE03F8446402C1E6AF3095157C078316AE03F84464062B49B9C045157C078316AE03F8446400500000062B49B9C045157C0CD7FDD966A844640974ACD45FF5057C0CD7FDD966A844640974ACD45FF5057C062537A447584464062B49B9C045157C062537A447584464062B49B9C045157C0CD7FDD966A84464005000000D8CFF63CDF5057C04E8A30852A84464043FC598FD45057C04E8A30852A84464043FC598FD45057C0E35DCD3235844640D8CFF63CDF5057C0E35DCD3235844640D8CFF63CDF5057C04E8A30852A84464006000000F787384A0F5157C04E8A30852A844640F787384A0F5157C0B9B693D71F84464062B49B9C045157C0B9B693D71F84464062B49B9C045157C04E8A30852A8446402C1E6AF3095157C04E8A30852A844640F787384A0F5157C04E8A30852A8446400500000062B49B9C045157C04E8A30852A844640974ACD45FF5057C04E8A30852A844640974ACD45FF5057C078316AE03F84464062B49B9C045157C078316AE03F84464062B49B9C045157C04E8A30852A844640050000003B22081E6F5057C00D05078E4A84464071B839C7695057C00D05078E4A84464071B839C7695057C0A2D8A33B558446403B22081E6F5057C0A2D8A33B558446403B22081E6F5057C00D05078E4A844640050000006DA393EAE95057C04E8A30852A8446406DA393EAE95057C0E35DCD323584464002773098F45057C0E35DCD323584464002773098F45057C04E8A30852A8446406DA393EAE95057C04E8A30852A84464005000000D8CFF63CDF5057C04E8A30852A8446406DA393EAE95057C04E8A30852A8446406DA393EAE95057C0B9B693D71F844640D8CFF63CDF5057C0B9B693D71F844640D8CFF63CDF5057C04E8A30852A844640050000006DA393EAE95057C08F0F5A7C0A8446406DA393EAE95057C0FA3BBDCEFF834640A339C593E45057C0FA3BBDCEFF834640A339C593E45057C08F0F5A7C0A8446406DA393EAE95057C08F0F5A7C0A8446400500000002773098F45057C024E3F62915844640380D6241EF5057C024E3F62915844640380D6241EF5057C0B9B693D71F84464002773098F45057C0B9B693D71F84464002773098F45057C024E3F62915844640060000003B22081E6F5057C062537A44758446403B22081E6F5057C0CD7FDD966A84464071B839C7695057C0CD7FDD966A844640A64E6B70645057C0CD7FDD966A844640A64E6B70645057C062537A44758446403B22081E6F5057C062537A4475844640050000003B22081E6F5057C0CD7FDD966A844640068CD674745057C0CD7FDD966A844640068CD674745057C038AC40E95F8446403B22081E6F5057C038AC40E95F8446403B22081E6F5057C0CD7FDD966A84464009000000068CD674745057C0CD7FDD966A844640068CD674745057C0F72617F27F844640D0F5A4CB795057C0F72617F27F844640D0F5A4CB795057C062537A44758446409B5F73227F5057C062537A4475844640303310D0895057C062537A4475844640303310D0895057C0CD7FDD966A844640D0F5A4CB795057C0CD7FDD966A844640068CD674745057C0CD7FDD966A84464005000000D8CFF63CDF5057C062537A4475844640D8CFF63CDF5057C0CD7FDD966A8446400E6628E6D95057C0CD7FDD966A8446400E6628E6D95057C062537A4475844640D8CFF63CDF5057C062537A447584464005000000380D6241EF5057C062537A4475844640380D6241EF5057C0CD7FDD966A844640A339C593E45057C0CD7FDD966A844640A339C593E45057C062537A4475844640380D6241EF5057C062537A4475844640', 10) geom);
