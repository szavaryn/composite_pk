# composite_pk
Quite often issue is a necessity of composite primary keys creating due to different raw data problems on CRM / databases side.

Let's consider the following example: 
#|
| f | f |
|#
_________________________________________________________________
id   |   name                     | city    |  address          |
1001 | Shumakov Medical Center    | Moscow  | Pekhotnaya st. 5  |
1005 | Medical Center of Shumakov | Moscow  | Pekhotnaya st. 5  |
1012 | Medical Center of Shumakov | Moscow  | 5 Pekhotnaya st.  |
_________________________________________________________________

That's the same organization but due to some manual processes it appears three times in this table. Each id could has its own corresponding data from other tables, overall impact of such duplication on strategic metrics could be significant. So I want to deduplicate it somehow and create the composite primary key for further aggregation of corresponding data: like max/min values, list of values, etc.
Unfortunately it looks like really common issue.
