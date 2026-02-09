Login credentials for testing:

- Email: admin@goalhub.com
- Password: superadmin123

admin@goalhub.com

"Use headsup-planner to analyze current sprint state"

- "Use headsup-implementer to implement [feature]"
- "Use headsup-tester to run tests"

mailbox: http://localhost:4000/dev/mailbox/
./bin/heads_up remote

HeadsUp.Auth.register_user(%{  
 email: "admin@goalhub.com",  
 password: "superadmin123",  
 role: "admin",  
 user_name: "admin",  
 name: "Admin User"  
 })
