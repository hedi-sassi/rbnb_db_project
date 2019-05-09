


------------------------------------------------------------------
--query 7

select AMENITY_NAME, NEIGHBORHOOD 

from 

(select AMENITY_NAME, AMEN_COUNT, NEIGHBORHOOD , rank() over(partition by ordered_data.NEIGHBORHOOD order by AMEN_COUNT desc) as rank --rank the data with respect to neighborhood

from 

  (select distinct AMENITY_NAME, AMEN_COUNT, NEIGHBORHOOD 
  from 

    (select AM.AMENITY_NAME, count(AMENITY_NAME) over(partition by LOC.NEIGHBORHOOD, AM.AMENITY_NAME) as amen_count, LOC.NEIGHBORHOOD   --count the amenities with respect to their names
    from LISTING_LOCATION LOC, AMENITIES AM, LISTING_AMENITIES LA
    where LOC.LISTING_ID = LA.LISTING_ID and LA.AMENITY_ID = AM.AMENITY_ID and LOC.LISTING_ID in (

      select L.LISTING_ID
      from LISTING L, MATERIAL_DESCRIPTION MD
      where L.LISTING_ID = MD.LISTING_ID and L.CITY = 'Berlin' and MD.ROOM_TYPE = 'Private room'    --listings with private room in berlin

      )
    ) data_amen

  order by data_amen.NEIGHBORHOOD, data_amen.amen_count desc) ordered_data    --order the data with respect to the neighborhood
  ) ranked_data

where ranked_data.rank <= 3   --select data with rank smaller than 3 ==>  select first 3 for each neighborhood

;


-------------------------------------------------------
--query 8

create view number_of_host_verif as
  select count(*) as verifications, HV.HOST_ID
  from HOST_VERIFICATIONS HV
  group by HV.HOST_ID;

select avg(average_most.avg_m - average_least.avg_l) as diff
from 
 
 (select coalesce(avg(RS1.REVIEW_SCORES_COMMUNICATION),0) as avg_m        --coalesce force result to be 0 if avg resturn NULL (e.g avg on empty set)
 from
 
    (select h.HOST_ID
    from      
      (select n.HOST_ID
      from number_of_host_verif n
      order by n.verifications desc) h     --host with the most verification
    where rownum = 1) host_most ,
    
    LISTING L1, REVIEWS_SCORES RS1
    
    where L1.LISTING_ID = RS1.LISTING_ID and L1.HOST_ID = host_most.HOST_ID and RS1.REVIEW_SCORES_COMMUNICATION is not null
  ) average_most

  ,

   (select coalesce(avg(RS2.REVIEW_SCORES_COMMUNICATION),0) as avg_l
    from
 
    (select h2.HOST_ID
    from      
      (select n2.HOST_ID
      from number_of_host_verif n2
      order by n2.verifications asc) h2     --host with the least verification
    where rownum = 1) host_least ,
    
    LISTING L2, REVIEWS_SCORES RS2
    
    where L2.LISTING_ID = RS2.LISTING_ID and L2.HOST_ID = host_least.HOST_ID and RS2.REVIEW_SCORES_COMMUNICATION is not null
  ) average_least

;


---------------------------------------------
--query 10

select total_listing.NEIGHBORHOOD
from 

(select count(*) as total, LOC2.NEIGHBORHOOD      --total number of listings per neighborhood
from LISTING_LOCATION LOC2, LISTING L3
where LOC2.LISTING_ID = L3.LISTING_ID and L3.CITY = 'Madrid' group by LOC2.NEIGHBORHOOD) total_listing 

,

(select count(*) as occupied_listings, LOC.NEIGHBORHOOD
from LISTING_LOCATION LOC, LISTING L2
where L2.LISTING_ID = LOC.LISTING_ID and L2.CITY = 'Madrid' and L2.LISTING_ID in (

  select distinct L1.LISTING_ID      --listing in madrid that were taken in 2019 
  from LISTING L1, CALENDAR CAL
  where CAL.CALENDAR_DATE >= date '2019-01-01' and CAL.AVAILABLE = 'f' and L1.LISTING_ID = CAL.LISTING_ID 
  and L1.LISTING_ID in (

    select L.LISTING_ID   --listing in madrid whose host is member since '2017-06-01' 
    from LISTING L, HOST H
    where L.CITY = 'Madrid' and L.HOST_ID = H.HOST_ID and H.HOST_SINCE >= date '2017-06-01' 
  )

) group by LOC.NEIGHBORHOOD) filtered_listing

where total_listing.NEIGHBORHOOD = filtered_listing.NEIGHBORHOOD and (filtered_listing.occupied_listings / total_listing.total) >= 0.5;


-----------------------------------------------------------------------------
--query 11

select filtered.COUNTRY
from 

(select count(*) as available, L.COUNTRY
from LISTING L
where L.LISTING_ID in (
 select distinct L1.LISTING_ID     
  from LISTING L1, CALENDAR CAL
  where CAL.CALENDAR_DATE >= date '2018-01-01' and CAL.CALENDAR_DATE < date '2019-01-01' and CAL.AVAILABLE = 't' and L1.LISTING_ID = CAL.LISTING_ID
  
) group by L.COUNTRY) filtered
 
,

(select count(*) total_listing, L2.COUNTRY
from LISTING L2
group by L2.COUNTRY) total

where filtered.COUNTRY = total.COUNTRY and (filtered.available/ total.total_listing) >= 0.2;

------------------------------------------------------------
--query 12


select total.NEIGHBORHOOD
from 

(select count(*) total_list, LOC.NEIGHBORHOOD
from LISTING_LOCATION LOC, LISTING L
where LOC.LISTING_ID = L.LISTING_ID and L.CITY = 'Barcelona' group by LOC.NEIGHBORHOOD) total

,

(
select count(*) strict_count, LOC.NEIGHBORHOOD
from LISTING_LOCATION LOC, LISTING_DETAILS LD, LISTING L2
where LOC.LISTING_ID = LD.LISTING_ID and L2.LISTING_ID = LD.LISTING_ID and L2.CITY = 'Barcelona' and LD.CANCELLATION_POLICY = 'strict_14_with_grace_period' group by LOC.NEIGHBORHOOD

) filtered

where total.NEIGHBORHOOD = filtered.NEIGHBORHOOD and (filtered.strict_count / total.total_list) >= 0.05;


------------------------------------------------------------
