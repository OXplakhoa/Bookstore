# Flash Sale Manual Testing Guide

## Quick Start

1. **Run the application:**
   ```powershell
   dotnet run
   ```

2. **Navigate to testing page:**
   - URL: `https://localhost:7197/Home/TestFlashSale`
   - This page has automated tests for countdown timers and UI components

3. **Login as Admin:**
   - Email: `admin@bookstore.local`
   - Password: `Admin@123`

---

## Test Scenario 1: Create a Flash Sale (5 minutes)

### Steps:
1. Navigate to `/Admin/FlashSales`
2. Click "Create New Flash Sale"
3. Fill in:
   - **Name:** "Black Friday Test Sale"
   - **Description:** "Testing flash sale functionality"
   - **Start Date:** Current time
   - **End Date:** Current time + 10 minutes
   - **IsActive:** Checked
4. Click "Save"
5. Click "Manage Products" on the created sale
6. Add 2-3 products:
   - Set sale price to 60% of original price
   - Set stock limit to 10 for one product
7. Save

### Expected Results:
✅ Flash sale appears in admin list with "Active" status  
✅ Products show in the flash sale management page  
✅ Discount percentage calculated automatically  

---

## Test Scenario 2: View Flash Sale on Homepage (2 minutes)

### Steps:
1. Navigate to homepage: `/`
2. Look for "Flash Sale - Đang diễn ra" section

### Expected Results:
✅ Flash sale section appears on homepage  
✅ Products display with flash sale badge  
✅ Countdown timer shows remaining time  
✅ Countdown updates every second  
✅ Original price has strikethrough  
✅ Sale price is red and prominent  
✅ Stock remaining shows (if limited)  

---

## Test Scenario 3: Product Details with Flash Sale (3 minutes)

### Steps:
1. Click on a flash sale product from homepage
2. Observe the product details page

### Expected Results:
✅ Large flash sale banner at top  
✅ Discount percentage displayed  
✅ Savings amount shown  
✅ Countdown timer active and updating  
✅ Original vs. sale price comparison clear  
✅ Stock limit progress bar (if applicable)  
✅ "Mua ngay" button is prominent and red  

---

## Test Scenario 4: Add Flash Sale Item to Cart (3 minutes)

### Steps:
1. On product details page, enter quantity: 2
2. Click "🔥 Mua ngay - Flash Sale" button
3. Navigate to cart: `/Cart`

### Expected Results:
✅ Success message appears  
✅ Cart count updates in navbar  
✅ Cart page shows flash sale price (not original price)  
✅ Total calculated with sale price  
✅ Flash sale indicator visible on cart item  

---

## Test Scenario 5: Checkout with Flash Sale Item (5 minutes)

### Steps:
1. From cart, click "Proceed to Checkout"
2. Fill in shipping information
3. Select payment method: COD
4. Click "Place Order"

### Expected Results:
✅ Checkout page shows correct sale prices  
✅ Total is calculated with flash sale prices  
✅ Order confirmation displays correct amounts  
✅ Order history shows flash sale was applied  
✅ Stock limit decremented (check admin flash sale products)  

---

## Test Scenario 6: Countdown Expiration (10+ minutes)

### Setup:
1. Create a flash sale with EndDate = Current time + 2 minutes
2. Add products to the sale

### Steps:
1. Navigate to product details page
2. Wait for countdown to reach 0

### Expected Results:
✅ Countdown shows "Đã kết thúc"  
✅ Page auto-reloads after 2 seconds  
✅ After reload, flash sale banner no longer appears  
✅ Product shows original price  
✅ Flash sale badge removed  

---

## Test Scenario 7: Stock Limit Enforcement (5 minutes)

### Setup:
1. Create flash sale with product having StockLimit = 3
2. SoldCount = 0

### Steps:
1. Add 3 items to cart
2. Complete checkout
3. Try adding the same product again

### Expected Results:
✅ First 3 items can be added at flash sale price  
✅ After 3rd order, stock limit reached  
✅ Product shows "Hết hàng (Flash Sale)" or reverts to regular price  
✅ SoldCount in database = 3  
✅ Cannot add more items at flash sale price  

---

## Test Scenario 8: Expired Flash Sale in Cart (7 minutes)

### Setup:
1. Create flash sale ending in 3 minutes
2. Add products to cart
3. Wait for flash sale to expire (don't checkout)

### Steps:
1. After expiration, try to proceed to checkout
2. Observe behavior

### Expected Results:
✅ Warning message appears  
✅ User informed flash sale expired  
✅ Price recalculated to regular price (or checkout blocked)  
✅ Clear explanation to user  

---

## Test Scenario 9: Mobile Responsiveness (5 minutes)

### Steps:
1. Open browser DevTools (F12)
2. Toggle device toolbar (Ctrl+Shift+M)
3. Select "iPhone 12 Pro" or similar
4. Navigate through:
   - Homepage flash sale section
   - Product listing page
   - Product details
   - Cart

### Expected Results:
✅ Flash sale section adapts to mobile (2 columns instead of 4)  
✅ Countdown remains readable  
✅ Badges don't overlap text  
✅ Buttons are touch-friendly  
✅ All text is legible  
✅ No horizontal scrolling  

---

## Test Scenario 10: Admin Analytics (3 minutes)

### Steps:
1. Navigate to `/Admin/FlashSales`
2. Click "Analytics" on a completed or active flash sale
3. Review the data

### Expected Results:
✅ Total units sold displayed  
✅ Total revenue calculated correctly  
✅ Product breakdown shows individual sales  
✅ Data matches order history  

---

## Browser Compatibility Tests

Test in each browser:

### Chrome
- [ ] Homepage flash sale section
- [ ] Countdown timer
- [ ] Product details
- [ ] Add to cart
- [ ] Checkout

### Firefox
- [ ] Homepage flash sale section
- [ ] Countdown timer
- [ ] Product details
- [ ] Add to cart
- [ ] Checkout

### Edge
- [ ] Homepage flash sale section
- [ ] Countdown timer
- [ ] Product details
- [ ] Add to cart
- [ ] Checkout

---

## JavaScript Console Tests

Open DevTools Console (F12) and run:

### Test 1: Count Active Timers
```javascript
const timers = document.querySelectorAll('[data-countdown-end]');
console.log(`Found ${timers.length} countdown timers`);
timers.forEach((el, i) => console.log(`Timer ${i+1}:`, el.textContent));
```

### Test 2: Force Expiration in 5 Seconds
```javascript
document.querySelectorAll('[data-countdown-end]').forEach(el => {
    el.setAttribute('data-countdown-end', new Date(Date.now() + 5000).toISOString());
});
window.initFlashSaleCountdowns();
console.log('Timers will expire in 5 seconds...');
```

### Test 3: Check for Memory Leaks
```javascript
// Note initial memory
console.log('Memory before:', performance.memory?.usedJSHeapSize);

// Navigate to flash sale page, then away, then back several times

// Check memory after
console.log('Memory after:', performance.memory?.usedJSHeapSize);
// Should not continuously increase
```

---

## SQL Database Tests

Run the SQL test script:
```powershell
# Option 1: Using sqlcmd
sqlcmd -S DESKTOP-JLJ00JT -d BookstoreDb -i "TestScripts\FlashSale_Tests.sql"

# Option 2: Using Azure Data Studio or SSMS
# Open TestScripts\FlashSale_Tests.sql and execute
```

### Key Checks:
- [ ] No overlapping flash sales for same product
- [ ] Decimal precision is correct (18,2)
- [ ] Foreign key constraints in place
- [ ] No orphaned flash sale products
- [ ] SoldCount matches actual orders

---

## Performance Tests

### Test Page Load Time
1. Open Chrome DevTools → Network tab
2. Hard refresh (Ctrl+Shift+R)
3. Check "DOMContentLoaded" time

**Success Criteria:**
- Homepage: < 2 seconds
- Product details: < 1.5 seconds
- Cart: < 1 second

### Test Countdown Performance
1. Create 50 flash sale products
2. Display all on a page
3. Monitor CPU usage in Task Manager

**Success Criteria:**
- CPU usage should remain stable
- No noticeable UI lag
- Smooth countdown updates

---

## Bug Reporting Template

When you find a bug, document it:

```
Bug #: [Number]
Title: [Short description]
Severity: Critical / High / Medium / Low
Found by: [Your name]
Date: [Date found]

Steps to Reproduce:
1. 
2. 
3. 

Expected Result:
[What should happen]

Actual Result:
[What actually happened]

Environment:
- Browser: 
- OS: 
- Screen Resolution: 

Screenshots:
[Attach if applicable]

Console Errors:
[Copy any JavaScript errors]

Database State:
[Relevant records from database]
```

---

## Test Progress Tracker

| Test Scenario | Status | Date | Tester | Notes |
|--------------|--------|------|--------|-------|
| 1. Create Flash Sale | ⬜ | | | |
| 2. Homepage Display | ⬜ | | | |
| 3. Product Details | ⬜ | | | |
| 4. Add to Cart | ⬜ | | | |
| 5. Checkout | ⬜ | | | |
| 6. Countdown Expiration | ⬜ | | | |
| 7. Stock Limit | ⬜ | | | |
| 8. Expired in Cart | ⬜ | | | |
| 9. Mobile Responsive | ⬜ | | | |
| 10. Admin Analytics | ⬜ | | | |

Legend: ⬜ Not Started | 🟡 In Progress | ✅ Passed | ❌ Failed

---

## Quick Reference URLs

- Homepage: `https://localhost:7197/`
- Products: `https://localhost:7197/Products`
- Cart: `https://localhost:7197/Cart`
- Admin Flash Sales: `https://localhost:7197/Admin/FlashSales`
- Test Page: `https://localhost:7197/Home/TestFlashSale`
- Login: `https://localhost:7197/Identity/Account/Login`

---

## Tips for Effective Testing

1. **Clear your browser cache** between major tests (Ctrl+Shift+Delete)
2. **Use Incognito/Private mode** to test as anonymous user
3. **Take screenshots** of any issues
4. **Check browser console** for JavaScript errors
5. **Monitor database** using SQL Server Management Studio
6. **Test in different browsers** - don't just use Chrome
7. **Use different screen sizes** - mobile, tablet, desktop
8. **Test edge cases** - empty data, maximum values, special characters
9. **Verify emails** if email notifications are implemented
10. **Check performance** with browser DevTools

---

## Next Steps After Testing

Once all tests pass:
1. ✅ Document all bugs found and fixed
2. ✅ Update test checklist with results
3. ✅ Get stakeholder approval
4. ✅ Move to Phase 7 (Optional Enhancements)
5. ✅ Plan deployment strategy

---

**Happy Testing! 🧪**
