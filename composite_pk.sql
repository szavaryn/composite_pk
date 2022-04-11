/*
Here we want to create composite key for its further using as primary keys. Let's image that we work with medical centers.
Initially we have a database with autoincremental integer keys. Nevertheless we found out that the same center could be duplicated with different keys due to
some differences in names, addresses of some other attributes. Usually the reason are some manually data updates.
We will use for this purpose names, latitude and longitude via H3 Uber open source library.
*/

--firstly we want to exclude the most common patterns from centers names
$exclusion_list = ['clinical', 'medical', 'doctor'];

--we're going to exclude this patterns and special symbols for further using "cleaned" medical centers names

$get_string_before_space = ($name) ->
{
    return 
    case when $name like '% %' 
    then Substring(ToLower(cast($name as utf8)), 0, Find( cast($name as utf8) , " ") )
    else ToLower(cast($name as utf8))
    end
};

$get_string_after_space = ($name) ->
{
    return 
    case when $name like '% %'
    then Substring(ToLower(cast($name as utf8)), Find( cast($name as utf8) , " ") + 1, GetLength( cast($name as utf8)) )
    else null 
    end 
};


$replace = ($name) ->
{
    return
    (
        RemoveAll(
        (
            ReplaceAll(
            (
                coalesce( 
                    (case 
                        when $get_string_before_space($name) in $exclusion 
                        then null
                        else $get_string_before_space($name) 
                    end)
                    , "")
                ||
                coalesce( 
                    (case 
                        when $get_string_before_space($get_string_after_space($name)) in $exclusion 
                        then null
                        else $get_string_before_space($get_string_after_space($name)) 
                    end)
                    , "")    
                ||
                coalesce( 
                    (case 
                        when $get_string_before_space($get_string_after_space($get_string_after_space($name))) in $exclusion 
                        then null
                        else $get_string_before_space($get_string_after_space($get_string_after_space($name))) 
                    end)
                    , "")    
                ||
                coalesce( 
                    (case 
                        when $get_string_before_space($get_string_after_space($get_string_after_space($get_string_after_space($name)))) in $exclusion 
                        then null
                        else $get_string_before_space($get_string_after_space($get_string_after_space($get_string_after_space($name)))) 
                    end)
                    , "")    
                ||
                coalesce( 
                    (case 
                        when $get_string_before_space($get_string_after_space($get_string_after_space($get_string_after_space($get_string_after_space($name))))) in $exclusion 
                        then null
                        else $get_string_before_space($get_string_after_space($get_string_after_space($get_string_after_space($get_string_after_space($name)))))
                    end)
                    , "")    
            ), "ё", "е")
        ),  " !№;%:?*()[]{}\/.,=+-_@#$^& ")
    )
};

--It's impossible to define all common texts patterns and that's why we need to use some part of centers names

$shorts = ($key) ->
{
    return 
    Substring( cast($key as utf8), 1, 4 )
}
;


--Using H3 library for creating hexagons
$geo = ($lon, $lat) ->
{
    return H3::FromGeo(cast($lon as double), cast($lat as double), 8)
};


--bigint hash and its replacement on initial id to avoid null values
$hash = ($key1, $key2, $change) ->
{
    return 
    (
        case 
            when $key1 is not null 
            and $key2 is not null 
        then XXH3(cast($key1 as utf8) || cast($key2 as utf8) ) 
        else cast($change as uint64)
        end
    )
}
;


insert into schema_name.new_pk with truncate
    select 
    id
    , $hash ($shorts(cleaned_name), h3geo, id) as new_pk
    from 
    (
        select
        id 
        , (case 
            when $replace(name) != ""
            then $replace(name)
            else name 
            end
        ) as cleaned_name         
        , $geo(location_lon, location_lat) as h3geo
        from schema_name.medical_centers
    )
;
