#!/usr/bin/env bash
set -euo pipefail
WS="$1"

# CSV 1: US date format, some nulls
cat > "$WS/customers.csv" << 'EOF'
id,name,email,signup_date,country
1,Alice Johnson,alice@example.com,01/15/2023,US
2,Bob Smith,bob@example.com,02/20/2023,UK
3,Carol Williams,carol@example.com,03/10/2023,US
4,David Brown,,04/05/2023,CA
5,Eve Davis,eve@example.com,,US
6,Frank Miller,frank@example.com,06/12/2023,UK
7,Grace Wilson,grace@example.com,07/08/2023,US
8,Hank Moore,hank@example.com,08/22/2023,CA
9,Ivy Taylor,ivy@example.com,09/30/2023,US
10,Jack Anderson,jack@example.com,10/15/2023,UK
1,Alice Johnson,alice@example.com,01/15/2023,US
11,Karen Thomas,karen@example.com,11/01/2023,US
12,Leo Jackson,,12/10/2023,CA
13,Mia White,mia@example.com,01/25/2024,US
14,Noah Harris,noah@example.com,02/14/2024,UK
15,Olivia Martin,olivia@example.com,03/20/2024,US
EOF

# CSV 2: ISO date format, different columns
cat > "$WS/orders.csv" << 'EOF'
order_id,customer_id,product,amount,order_date
1001,1,Widget A,29.99,2023-03-15
1002,3,Widget B,49.99,2023-04-20
1003,1,Widget C,19.99,2023-05-10
1004,5,Widget A,29.99,2023-06-01
1005,2,Widget D,99.99,2023-06-15
1006,7,Widget B,49.99,2023-07-20
1007,3,Widget A,29.99,2023-08-05
1008,10,Widget C,19.99,2023-09-12
1009,1,Widget D,99.99,2023-10-01
1010,8,Widget A,29.99,2023-10-20
1011,4,Widget B,49.99,2023-11-05
1012,6,Widget C,19.99,2023-11-22
1013,9,Widget A,29.99,2023-12-01
1014,11,Widget D,99.99,2024-01-10
1015,13,Widget B,49.99,2024-02-15
1001,1,Widget A,29.99,2023-03-15
1016,14,Widget A,29.99,2024-03-01
1017,15,Widget C,19.99,2024-03-15
1018,2,Widget B,49.99,2024-04-01
1019,7,Widget D,,2024-04-20
1020,3,Widget A,29.99,2024-05-01
EOF

# CSV 3: European date format, messy
cat > "$WS/feedback.csv" << 'EOF'
feedback_id,customer_id,rating,comment,feedback_date
F001,1,5,Great product!,15-03-2023
F002,3,4,Good quality,20-04-2023
F003,2,3,Average experience,15-06-2023
F004,5,5,Excellent!,01-06-2023
F005,7,2,Could be better,20-07-2023
F006,1,4,Fast delivery,01-10-2023
F007,10,5,Love it!,12-09-2023
F008,8,,No comment,20-10-2023
F009,4,3,OK product,05-11-2023
F010,9,4,Recommended,01-12-2023
F011,11,5,Amazing!,10-01-2024
F012,13,4,Good value,15-02-2024
F001,1,5,Great product!,15-03-2023
F013,14,3,Decent,01-03-2024
F014,15,5,Perfect!,15-03-2024
F015,2,4,Improved since last time,01-04-2024
EOF
