# DeMarket 
**Author:**
Lee Faria/33Audits

## DeMarket
Contract allows users to list, purchase, and withdraw funds from a decentralized marketplace.


### Design choices

Key Design Decisions in DeMarket Contract:

1. Decentralized User Management:
   - Users register with unique usernames
   - Utilizes a mapping for efficient user data storage and retrieval
   - Implements a User struct to store username, existence status, and purchase history

2. Flexible Item Listing:
   - Anyone can list items for sale once registered
   - Uses an Item struct to store comprehensive item details
   - Employs a mapping with auto-incrementing itemId for easy item management

3. Direct Ether Handling:
   - Accepts Ether payments for item purchases
   - Implements a balance system to hold seller funds until withdrawal
   - Includes a withdrawal function for sellers to claim their earnings

4. Purchase History Tracking:
   - Maintains an array of purchased item IDs for each user
   - Allows retrieval of a user's complete purchase history

5. Time-Independent Transactions:
   - No time restrictions on listings or purchases
   - Items remain available until sold, allowing for long-term listings

These design choices create a flexible decentralized marketplace. The user management allows for permissionless participation, while item listing system allows anyone to list an item as long as its not already available. Direct Ether handling simplifies transactions, and the purchase history feature logs user's purchase history.

