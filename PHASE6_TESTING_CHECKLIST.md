# Phase 6 - Testing & Edge Cases

## Testing Status: 🟡 IN PROGRESS

**Date Started:** November 2, 2025  
**Tester:** Development Team

---

## 1. Visual Testing ✅

### Flash Sale Badge Display
- [ ] Badge appears on product cards in product listing
- [ ] Badge appears on homepage flash sale section
- [ ] Badge has proper gradient animation
- [ ] Discount percentage displays correctly
- [ ] Badge positioning is correct (doesn't overlap product image incorrectly)

### Countdown Timer Display
- [ ] Countdown displays on product cards
- [ ] Countdown displays on product details page
- [ ] Countdown displays on homepage flash sale section
- [ ] Format is correct (days, hours, minutes, seconds)
- [ ] Text updates every second smoothly
- [ ] Multiple countdowns on same page work independently

### Price Display
- [ ] Original price has strikethrough styling
- [ ] Sale price is larger and red/prominent
- [ ] Savings amount displays correctly
- [ ] Price formatting matches site standards (₫ symbol, thousand separators)

### Responsive Design
- [ ] Desktop view (1920x1080)
- [ ] Laptop view (1366x768)
- [ ] Tablet view (768x1024)
- [ ] Mobile view (375x667)
- [ ] Cards stack properly on small screens
- [ ] Text remains readable at all sizes

---

## 2. Functional Testing ✅

### Countdown Timer Functionality
- [ ] Timer counts down correctly (verify with system clock)
- [ ] Timer reaches 0 and displays "Đã kết thúc"
- [ ] Product details page auto-reloads when countdown expires
- [ ] Countdown persists across page refreshes
- [ ] Multiple countdowns don't interfere with each other
- [ ] No JavaScript errors in browser console

### Flash Sale Activation
- [ ] Sale appears when StartDate <= CurrentTime < EndDate
- [ ] Sale doesn't appear before StartDate
- [ ] Sale disappears after EndDate
- [ ] IsActive=false prevents sale from showing (even if dates are valid)
- [ ] Sale price applies correctly during active period

### Add to Cart with Flash Sale
- [ ] Can add flash sale product to cart
- [ ] Locked price stored correctly in CartItem
- [ ] FlashSaleProductId stored in CartItem
- [ ] Cart displays correct sale price
- [ ] Cart total calculates with sale price

### Stock Limit Enforcement
- [ ] Products with StockLimit show remaining count
- [ ] Cannot add more than remaining stock limit to cart
- [ ] Progress bar shows correct percentage
- [ ] Warning message appears when low stock
- [ ] Stock limit updates after purchase

### Checkout with Flash Sale
- [ ] Checkout displays correct sale prices
- [ ] Total calculates correctly with flash sale items
- [ ] Can complete order with COD
- [ ] Can complete order with Stripe
- [ ] Order confirmation shows correct prices

### Order Tracking
- [ ] OrderItem.FlashSaleProductId is stored
- [ ] OrderItem.WasOnFlashSale flag is set correctly
- [ ] Order history shows flash sale indicator
- [ ] Unit price matches locked sale price

---

## 3. Edge Cases Testing ⚠️

### Timezone Handling
- [ ] Server uses UTC for all date comparisons
- [ ] Countdown displays correctly in user's local timezone
- [ ] StartDate/EndDate stored as UTC in database
- [ ] No off-by-one-hour errors (daylight saving time)

**Test Method:**
```csharp
// In Admin create flash sale, verify dates are saved as UTC
var flashSale = await _context.FlashSales.FindAsync(id);
Console.WriteLine($"Stored as: {flashSale.EndDate.Kind}"); // Should be UTC
```

### Expired Flash Sale in Cart
**Scenario:** User adds item to cart during flash sale, but sale expires before checkout.

**Expected Behavior:**
- [ ] CheckoutController detects expired flash sale
- [ ] Shows warning message to user
- [ ] Prevents checkout OR recalculates to regular price
- [ ] User is informed about price change

**Test Steps:**
1. Create flash sale ending in 2 minutes
2. Add product to cart
3. Wait for sale to expire
4. Attempt checkout
5. Verify behavior

### Concurrent Flash Sales
**Scenario:** Same product in multiple active flash sales (if allowed).

**Expected Behavior:**
- [ ] System prevents creating overlapping sales for same product
- [ ] Validation error shown in admin interface
- [ ] Database constraint prevents duplicate active sales

**Test Steps:**
1. Create Flash Sale A for Product 1
2. Try creating Flash Sale B for same Product 1 with overlapping dates
3. Verify error message

### Stock Depletion During Flash Sale
**Scenario:** Product has StockLimit=50, and 50 orders are placed.

**Expected Behavior:**
- [ ] SoldCount increments correctly
- [ ] When SoldCount reaches StockLimit, "Add to Cart" disabled
- [ ] Remaining count shows 0
- [ ] Clear message: "Flash Sale đã hết hàng"

**Test Steps:**
1. Create flash sale with StockLimit=5
2. Place 5 orders
3. Verify 6th order cannot be placed at flash sale price

### Product Stock vs Flash Sale Stock Limit
**Scenario:** Product.Stock=100, FlashSaleProduct.StockLimit=20.

**Expected Behavior:**
- [ ] Only 20 units available at flash sale price
- [ ] After 20 flash sales, product still available at regular price
- [ ] Cart logic respects the lower of (Product.Stock, FlashSale remaining)

**Test Steps:**
1. Create product with Stock=100
2. Create flash sale with StockLimit=20
3. Add 20 to cart at flash sale price (should work)
4. Try adding 21st at flash sale price (should fail or show regular price)

### Price Changes During Active Sale
**Scenario:** Admin changes Product.Price while flash sale is active.

**Expected Behavior:**
- [ ] FlashSaleProduct.OriginalPrice remains unchanged (snapshot)
- [ ] FlashSaleProduct.SalePrice remains unchanged
- [ ] Display still shows original prices from when sale was created
- [ ] No confusion for customers

**Test Steps:**
1. Create flash sale for Product (Price=100,000₫, SalePrice=70,000₫)
2. Admin changes Product.Price to 120,000₫
3. Verify flash sale still shows 100,000₫ → 70,000₫

### Deleted Products in Flash Sale
**Scenario:** Admin tries to delete a product currently in active flash sale.

**Expected Behavior:**
- [ ] DeleteBehavior.Restrict prevents deletion
- [ ] Error message: "Cannot delete product in active flash sale"
- [ ] Admin must remove from flash sale first, then delete

**Test Steps:**
1. Create active flash sale with products
2. Try to delete one of the products
3. Verify cannot delete

### Flash Sale Creation Validation
**Scenario:** Admin enters invalid data.

**Test Cases:**
- [ ] StartDate > EndDate → Error: "End date must be after start date"
- [ ] SalePrice > OriginalPrice → Error: "Sale price must be less than original"
- [ ] SalePrice <= 0 → Error: "Sale price must be positive"
- [ ] EndDate in past → Warning: "Flash sale will be expired immediately"
- [ ] Duplicate product in same flash sale → Error: "Product already in this flash sale"

### Browser Compatibility
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Edge (latest)
- [ ] Safari (macOS)
- [ ] Safari (iOS)
- [ ] Chrome (Android)

### Performance Testing
- [ ] Page with 20 flash sale products loads quickly (<2 seconds)
- [ ] Countdown timers don't cause CPU spike
- [ ] No memory leaks (countdowns clean up properly)
- [ ] Database queries use indexes (check execution plans)

---

## 4. Database Testing 🗄️

### Data Integrity
- [ ] FlashSaleProduct.OriginalPrice matches Product.Price at creation time
- [ ] FlashSaleProduct.DiscountPercentage calculated correctly
- [ ] FlashSaleProduct.SoldCount increments after successful orders
- [ ] CartItem.LockedPrice stores correct flash sale price
- [ ] OrderItem.FlashSaleProductId references correct flash sale

### Migration Testing
- [ ] Can rollback flash sale migration without data loss
- [ ] Decimal precision is correct (18,2)
- [ ] Foreign key constraints work correctly
- [ ] Indexes exist on frequently queried columns

**Run Migration Test:**
```powershell
# Rollback to before flash sale
dotnet ef database update AddFlashSaleToOrderItem

# Re-apply flash sale migrations
dotnet ef database update

# Check for data integrity
```

---

## 5. Security Testing 🔒

### Authorization
- [ ] Only Admin can create/edit/delete flash sales
- [ ] Anonymous users cannot access admin flash sale pages
- [ ] Regular users cannot manipulate flash sale prices via browser tools

### Input Validation
- [ ] SQL injection attempts blocked
- [ ] XSS attempts in flash sale name/description blocked
- [ ] Price manipulation in API calls blocked
- [ ] FlashSaleProductId tampering detected

**Test Cases:**
1. Try accessing `/Admin/FlashSales` as anonymous user → Redirect to login
2. Try accessing as regular user → Forbidden
3. Try sending negative SalePrice via API → Validation error

### Anti-Forgery Token
- [ ] All POST requests require valid anti-forgery token
- [ ] Cart add with flash sale requires token
- [ ] Admin actions require token

---

## 6. Error Handling Testing ⚠️

### Network Errors
- [ ] Countdown continues if user loses internet briefly
- [ ] Add to cart shows error message if API fails
- [ ] Graceful degradation if JavaScript disabled

### Database Errors
- [ ] Proper error messages if database unavailable
- [ ] Transaction rollback works correctly
- [ ] No partial data saved on failure

### Invalid Data
- [ ] Handles corrupted FlashSaleProductId in cart
- [ ] Handles deleted flash sale referenced in order history
- [ ] Handles missing product images gracefully

---

## 7. User Experience Testing 👤

### Clarity
- [ ] Users understand what flash sale means
- [ ] Countdown is prominent and easy to read
- [ ] Savings amount is clearly displayed
- [ ] "Limited stock" warnings are noticeable

### Urgency
- [ ] Red/urgent colors used appropriately
- [ ] Countdown creates sense of urgency
- [ ] "Chỉ còn X sản phẩm" message effective
- [ ] CTA buttons are prominent ("Mua ngay")

### Accessibility
- [ ] Countdown has proper ARIA labels
- [ ] Color contrast meets WCAG standards
- [ ] Keyboard navigation works
- [ ] Screen reader compatibility

---

## 8. Admin Experience Testing 👨‍💼

### Flash Sale Management
- [ ] Easy to create new flash sale
- [ ] Date/time pickers are intuitive
- [ ] Product search/selection is smooth
- [ ] Can easily see active vs expired sales
- [ ] Can toggle IsActive flag quickly

### Feedback
- [ ] Success messages after creating flash sale
- [ ] Validation errors are clear
- [ ] Can preview flash sale before publishing
- [ ] Can see how many products sold during flash sale

---

## 9. Automated Testing Scripts 🤖

### JavaScript Console Tests

**Test 1: Force Countdown to Expire in 5 Seconds**
```javascript
// Run in browser console
document.querySelectorAll('[data-countdown-end]').forEach(el => {
    el.setAttribute('data-countdown-end', new Date(Date.now() + 5000).toISOString());
});
window.initFlashSaleCountdowns();
console.log('Countdown will expire in 5 seconds...');
```

**Test 2: Check All Countdowns Are Running**
```javascript
// Run in browser console
const countdowns = document.querySelectorAll('[data-countdown-end]');
console.log(`Found ${countdowns.length} countdown timers`);
countdowns.forEach((el, i) => {
    console.log(`Timer ${i+1}:`, el.textContent);
});
```

**Test 3: Verify No Memory Leaks**
```javascript
// Run before and after navigation
console.log('Active intervals:', performance.memory?.usedJSHeapSize);
// Navigate to flash sale page, then away, then back
// Memory should not continuously increase
```

### SQL Query Tests

**Test 1: Find Overlapping Flash Sales**
```sql
-- Should return 0 rows if validation works
SELECT fsp1.ProductId, COUNT(*) 
FROM FlashSaleProducts fsp1
JOIN FlashSales fs1 ON fsp1.FlashSaleId = fs1.FlashSaleId
JOIN FlashSaleProducts fsp2 ON fsp1.ProductId = fsp2.ProductId AND fsp1.FlashSaleProductId != fsp2.FlashSaleProductId
JOIN FlashSales fs2 ON fsp2.FlashSaleId = fs2.FlashSaleId
WHERE fs1.IsActive = 1 AND fs2.IsActive = 1
  AND fs1.StartDate < fs2.EndDate 
  AND fs1.EndDate > fs2.StartDate
GROUP BY fsp1.ProductId
HAVING COUNT(*) > 1;
```

**Test 2: Verify Decimal Precision**
```sql
SELECT COLUMN_NAME, DATA_TYPE, NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('FlashSaleProducts')
  AND DATA_TYPE = 'decimal';
-- Should show decimal(18,2)
```

**Test 3: Check Active Flash Sales**
```sql
DECLARE @Now DATETIME = GETUTCDATE();
SELECT 
    fs.Name,
    fs.StartDate,
    fs.EndDate,
    COUNT(fsp.FlashSaleProductId) AS ProductCount,
    CASE 
        WHEN fs.StartDate > @Now THEN 'Upcoming'
        WHEN fs.EndDate < @Now THEN 'Expired'
        WHEN fs.IsActive = 0 THEN 'Disabled'
        ELSE 'Active'
    END AS Status
FROM FlashSales fs
LEFT JOIN FlashSaleProducts fsp ON fs.FlashSaleId = fsp.FlashSaleId
GROUP BY fs.FlashSaleId, fs.Name, fs.StartDate, fs.EndDate, fs.IsActive;
```

---

## 10. Load Testing 📊

### Scenario: Black Friday Flash Sale
**Goal:** Ensure system handles high traffic during popular flash sales.

**Test Setup:**
- 100 concurrent users
- All browsing flash sale products
- 50% add items to cart
- 25% complete checkout

**Tools:**
- JMeter or k6 for load testing
- Application Insights for monitoring

**Success Criteria:**
- [ ] Page load time < 3 seconds under load
- [ ] No database deadlocks
- [ ] Cart operations complete successfully
- [ ] Stock limits enforced correctly (no overselling)
- [ ] Countdown timers don't impact server performance

---

## 11. Regression Testing 🔄

### Ensure Flash Sale Doesn't Break Existing Features
- [ ] Regular products (non-flash-sale) still work
- [ ] Cart works with mix of regular and flash sale items
- [ ] Checkout works with only regular items
- [ ] Order history for old orders (pre-flash-sale) displays correctly
- [ ] Product search/filter still works
- [ ] Category browsing unaffected
- [ ] User favorites unaffected
- [ ] Recently viewed unaffected

---

## 12. Documentation Testing 📚

- [ ] Admin can understand how to create flash sale from UI alone
- [ ] Error messages are helpful (not technical)
- [ ] Help text is provided where needed
- [ ] API documentation updated (if applicable)

---

## Bug Tracking Template

When you find a bug, document it like this:

```markdown
### Bug #[NUMBER]: [Short Description]

**Severity:** Critical / High / Medium / Low
**Status:** Open / In Progress / Fixed / Won't Fix

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happens]

**Environment:**
- Browser: 
- OS: 
- Date/Time: 

**Screenshots/Logs:**
[Attach if applicable]

**Fix:**
[Describe the solution once implemented]
```

---

## Testing Progress

**Phase 6 Started:** November 2, 2025  
**Target Completion:** [Set date]  
**Bugs Found:** 0  
**Bugs Fixed:** 0  
**Test Pass Rate:** 0%

---

## Next Steps After Phase 6

Once all tests pass:
1. ✅ Deploy to staging environment
2. ✅ Perform smoke tests
3. ✅ User acceptance testing (UAT)
4. ✅ Move to Phase 7 (Optional Enhancements)

---

**Notes:**
- Check items as you complete them
- Document any issues found
- Prioritize critical bugs
- Retest after fixes
