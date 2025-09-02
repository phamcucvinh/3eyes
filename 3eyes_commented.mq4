//+---------------------------------------------------------------------------+
//|                                                     3eyes.mq4            |
//|                        Pair Trading EA with Divergence Strategy         |
//|          This EA trades based on price divergence between two symbols    |
//|                              Version 1.00 (2025)                        |
//+---------------------------------------------------------------------------+
/*
 * STRATEGY OVERVIEW:
 * ==================
 * This EA implements a pair trading strategy that monitors price divergence 
 * between two forex symbols (e.g., current chart symbol and USDJPY overlay).
 * 
 * KEY CONCEPTS:
 * - Primary Symbol: The chart symbol where EA is attached
 * - Overlay Symbol: Secondary symbol (JJ1) for comparison
 * - Divergence: Price difference between the two symbols
 * - Entry Levels: 11 escalating levels based on increasing divergence
 * - Pair Trading: When symbols diverge, EA buys one and sells the other
 * 
 * TRADING LOGIC:
 * 1. Monitor divergence between primary and overlay symbols
 * 2. When divergence exceeds threshold, open opposite positions
 * 3. Scale into larger positions as divergence increases
 * 4. Close positions when divergence converges or profit targets hit
 * 5. Reset strategy when all positions are closed
 */

// EA properties and copyright information
#property copyright "nomadtown2025"      // EA copyright
#property link      ""                   // Support link 
#property version   "1.00"               // Version number
#property strict                         // Strict compilation mode for better error checking

// EA identifier for overlay/indicator communication
#define JJ_NAME "nomadtown2025"          // Name used for custom indicator calls

// Optional standard library - currently commented out
//#include <stdlib.mqh>                  // Standard MQL4 library for additional functions

//+---------------------------------------------------------------------------+
//|                           INPUT PARAMETERS                               |
//+---------------------------------------------------------------------------+

// === EA Configuration Section ===
input string EAConfig = "";              // Configuration header separator
input int magicNumber = 123456;          // Magic number for identifying EA's orders
input int slippage = 20;                 // Maximum acceptable slippage in points
input color buyColor = clrYellow;        // Chart color for buy order markers
input color sellColor = clrRed;          // Chart color for sell order markers  
input color closeColor = clrAqua;        // Chart color for close order markers
input int ordertryMax = 10;              // Maximum retry attempts for failed orders

// === Symbol Configuration Section ===
input string JJConfig = "";              // Pair trading configuration header
input string JJ1 = "USDJPY";             // Secondary symbol for pair trading (overlay symbol)

// === Entry Level Configuration ===
input string entryConfig = "";           // Entry level configuration header

// Entry Level 1 - Initial divergence threshold
input int kairi1 = 200;                  // 1st divergence point in points (200 points = 20 pips on 4-digit broker)
input double lots1 = 0.01;               // 1st level lot size (minimum lot size)
input double TP1 = 1.0;                  // 1st level take profit target in USD

// Entry Level 2 - Second divergence escalation
input int kairi2 = 250;                  // 2nd divergence point in points (250 points = 25 pips)  
input double lots2 = 0.01;               // 2nd level lot size
input double TP2 = 1.0;                  // 2nd level take profit target in USD

// Entry Level 3 - Third divergence escalation
input int kairi3 = 300;                  // 3rd divergence point in points (300 points = 30 pips)
input double lots3 = 0.01;               // 3rd level lot size
input double TP3 = 1.0;                  // 3rd level take profit target in USD

// Entry Level 4 - Fourth divergence escalation  
input int kairi4 = 350;                  // 4th divergence point in points (350 points = 35 pips)
input double lots4 = 0.01;               // 4th level lot size
input double TP4 = 1.0;                  // 4th level take profit target in USD

// Entry Level 5 - Fifth divergence escalation
input int kairi5 = 400;                  // 5th divergence point in points (400 points = 40 pips)
input double lots5 = 0.01;               // 5th level lot size  
input double TP5 = 1.0;                  // 5th level take profit target in USD

// Entry Level 6 - Sixth divergence escalation
input int kairi6 = 450;                  // 6th divergence point in points (450 points = 45 pips)
input double lots6 = 0.01;               // 6th level lot size
input double TP6 = 1.0;                  // 6th level take profit target in USD

// Entry Level 7 - Seventh divergence escalation  
input int kairi7 = 500;                  // 7th divergence point in points (500 points = 50 pips)
input double lots7 = 0.01;               // 7th level lot size
input double TP7 = 1.0;                  // 7th level take profit target in USD

// Entry Level 8 - Eighth divergence escalation
input int kairi8 = 550;                  // 8th divergence point in points (550 points = 55 pips)
input double lots8 = 0.01;               // 8th level lot size
input double TP8 = 1.0;                  // 8th level take profit target in USD

// Entry Level 9 - Ninth divergence escalation
input int kairi9 = 600;                  // 9th divergence point in points (600 points = 60 pips)
input double lots9 = 0.01;               // 9th level lot size
input double TP9 = 1.0;                  // 9th level take profit target in USD (Note: Comment says 3rd but should be 9th)

// Entry Level 10 - Tenth divergence escalation
input int kairi10 = 650;                 // 10th divergence point in points (650 points = 65 pips)
input double lots10 = 0.01;              // 10th level lot size
input double TP10 = 1.0;                 // 10th level take profit target in USD

// Entry Level 11 - Maximum divergence escalation  
input int kairi11 = 700;                 // 11th divergence point in points (700 points = 70 pips)
input double lots11 = 0.01;              // 11th level lot size
input double TP11 = 1.0;                 // 11th level take profit target in USD

// === Exit Configuration Section ===
input string exitConfig = "";            // Exit strategy configuration header  
input int exitKairi = 100;               // Convergence threshold for closing all positions (points)

//+---------------------------------------------------------------------------+
//|                     CUSTOM INDICATOR PARAMETERS                          |
//+---------------------------------------------------------------------------+
// These parameters are passed to the custom overlay indicator for chart display

color JJ2 = Yellow;                      // Overlay indicator color 1 (Yellow for upward signals)
color JJ3 = Red;                         // Overlay indicator color 2 (Red for downward signals)
bool JJ4 = false;                        // Overlay display toggle flag
color JJ5 = White;                       // Background/neutral color for overlay
bool JJ6 = false;                        // Secondary overlay feature toggle
bool JJ7 = true;                         // Main overlay visibility control
string JJ8 = "----------------------------------------------------"; // Visual separator for overlay
int JJ9 = 0;                            // Overlay position offset
ENUM_BASE_CORNER JJ10 = CORNER_LEFT_UPPER; // Overlay anchor corner position
string JJ11 = "overlay";                 // Overlay label text
string JJ12 = "Arial";                   // Font family for overlay text
int JJ13 = 10;                           // Font size for overlay display                                                       
color JJ14 = clrLime;                    // Positive signal color (Lime green)
color JJ15 = clrRed;                     // Negative signal color (Red)
string JJ16 = "Overlay OFF";             // Status text when overlay is disabled                        
string JJ17 = "start ON";                // Status text when EA is active
color JJ18 = clrDimGray;                 // Secondary UI color (Gray)
color JJ19 = clrBlack;                   // Text/border color (Black)
int JJ20 = 500;                          // Overlay refresh interval in milliseconds                                                                  
int JJ21 = 0;                            // Horizontal position offset for overlay                                                                      
int JJ22 = 90;                           // Vertical position offset for overlay                                                                  
int JJ23 = 20;                           // Text spacing parameter                                                               
string JJ24 = "tick.wav";                // Sound file for trading notifications     
string JJ25 = "----------------------------------------------------"; // Bottom separator line

//+---------------------------------------------------------------------------+
//|                        GLOBAL VARIABLES                                  |
//+---------------------------------------------------------------------------+

// Dynamic arrays to store trading parameters for each entry level (0-10 indices)
double lots[11];                         // Array storing lot sizes for each trading level
double TP[11];                           // Array storing take profit targets for each level
int kairi[11];                           // Array storing divergence thresholds for each level

// Trading state tracking variables
int lastNumber = 0;                      // Tracks the current entry level (0-10)
                                        // Represents how many entry levels have been activated

// Price tracking variables for divergence calculation
double lastTick = 0,                    // Previous price of primary symbol (_Symbol)
       lastSymbolTick = 0;              // Previous price of secondary symbol (JJ1 - overlay symbol)

//+---------------------------------------------------------------------------+
//| Expert initialization function                                            |
//| Called once when EA is first loaded onto chart                           |
//+---------------------------------------------------------------------------+

int OnInit() {
      // Initialize lot size array from input parameters
      // This allows dynamic access to lot sizes based on entry level
      lots[0] = lots1;                   // Entry level 1 lot size
      lots[1] = lots2;                   // Entry level 2 lot size
      lots[2] = lots3;                   // Entry level 3 lot size
      lots[3] = lots4;                   // Entry level 4 lot size
      lots[4] = lots5;                   // Entry level 5 lot size
      lots[5] = lots6;                   // Entry level 6 lot size
      lots[6] = lots7;                   // Entry level 7 lot size
      lots[7] = lots8;                   // Entry level 8 lot size
      lots[8] = lots9;                   // Entry level 9 lot size
      lots[9] = lots10;                  // Entry level 10 lot size
      lots[10] = lots11;                 // Entry level 11 lot size (maximum)
       
      // Initialize take profit array from input parameters
      // Each level can have different profit targets
      TP[0] = TP1;                       // Entry level 1 take profit target
      TP[1] = TP2;                       // Entry level 2 take profit target
      TP[2] = TP3;                       // Entry level 3 take profit target
      TP[3] = TP4;                       // Entry level 4 take profit target
      TP[4] = TP5;                       // Entry level 5 take profit target
      TP[5] = TP6;                       // Entry level 6 take profit target
      TP[6] = TP7;                       // Entry level 7 take profit target
      TP[7] = TP8;                       // Entry level 8 take profit target
      TP[8] = TP9;                       // Entry level 9 take profit target
      TP[9] = TP10;                      // Entry level 10 take profit target
      TP[10] = TP11;                     // Entry level 11 take profit target
       
      // Initialize divergence threshold array from input parameters
      // These define when each entry level should trigger
      kairi[0] = kairi1;                 // Entry level 1 divergence threshold (200 points)
      kairi[1] = kairi2;                 // Entry level 2 divergence threshold (250 points)
      kairi[2] = kairi3;                 // Entry level 3 divergence threshold (300 points)
      kairi[3] = kairi4;                 // Entry level 4 divergence threshold (350 points)
      kairi[4] = kairi5;                 // Entry level 5 divergence threshold (400 points)
      kairi[5] = kairi6;                 // Entry level 6 divergence threshold (450 points)
      kairi[6] = kairi7;                 // Entry level 7 divergence threshold (500 points)
      kairi[7] = kairi8;                 // Entry level 8 divergence threshold (550 points)
      kairi[8] = kairi9;                 // Entry level 9 divergence threshold (600 points)
      kairi[9] = kairi10;                // Entry level 10 divergence threshold (650 points)
      kairi[10] = kairi11;               // Entry level 11 divergence threshold (700 points)
       
      return INIT_SUCCEEDED;             // Initialization completed successfully
}

//+---------------------------------------------------------------------------+
//| Expert deinitialization function                                         |
//| Called when EA is removed from chart or terminal is closed              |
//+---------------------------------------------------------------------------+

void OnDeinit(const int reason) {
      // Reset trading state unless EA is being reloaded due to parameter change
      // This prevents losing position tracking during parameter updates
      if (reason != REASON_PARAMETERS) {
            lastNumber = 0;              // Reset entry level counter to 0
            // Note: Active positions remain open, only internal tracking is reset
      }
      // If reason == REASON_PARAMETERS, preserve lastNumber to maintain trading state
}

//+---------------------------------------------------------------------------+
//| Expert tick function - Main EA logic executed on every price tick       |
//| This is the heart of the EA where all trading decisions are made        |
//+---------------------------------------------------------------------------+

void OnTick()
{
      /*
       * MAIN TRADING ALGORITHM FLOW:
       * ============================
       * 1. Time and account validation
       * 2. Get current prices from custom overlay indicator
       * 3. Initialize price tracking on first run
       * 4. Calculate current and previous divergence
       * 5. Check for convergence exit conditions
       * 6. Check for individual position exit conditions  
       * 7. Reset strategy when all positions closed
       * 8. Check for new entry conditions based on divergence
       * 9. Execute pair trades when conditions met
       * 10. Update price tracking variables
       * 11. Display current status information
       */

      // === VALIDATION CHECKS ===
      
      // Time-based protection: Stop trading after 2023
      // This appears to be a time-limited EA version
      if (2023 < Year()) {
            return;      // Exit if current year is greater than 2023
      }
    
      // Account-based protection: Skip specific demo account
      // Prevents EA from running on certain test accounts
      if (AccountNumber() == 500000) {    
            return;  // Exit if running on account number 500000
      }
      
      // === OVERLAY PRICE RETRIEVAL ===
      
      /* Get current price from custom overlay indicator
       * The iCustom call retrieves data from the overlay indicator
       * Parameters breakdown:
       * - _Symbol, _Period: Current chart symbol and timeframe
       * - JJ_NAME: Indicator name ("nomadtown2025")  
       * - JJ1-JJ25: All the overlay indicator parameters
       * - 2: Buffer index (price buffer)
       * - 0: Bar index (current bar)
       */
      double currSymbolTick = iCustom(_Symbol, _Period, JJ_NAME, JJ1, JJ2, JJ3, JJ4, JJ5, JJ6, JJ7, JJ8, JJ9, JJ10, JJ11, JJ12, JJ13, JJ14, JJ15, JJ16, JJ17, JJ18, JJ19, JJ20, JJ21, JJ22, JJ23, JJ24, JJ25, 2, 0);
       
      // === FIRST BOOT INITIALIZATION ===
      
      // Initialize price tracking variables on first execution
      if (lastSymbolTick == 0 || lastTick == 0) {
            lastSymbolTick = currSymbolTick;  // Store overlay symbol price
            lastTick = Close[0];              // Store primary symbol price
            return;                           // Skip trading logic on first run
      }
       
      // === DIVERGENCE CALCULATIONS ===
      
      /* Calculate current divergence between symbols
       * kairiPoint = absolute difference between overlay and primary symbol
       * This measures how far apart the two symbols have moved
       */
      int kairiPoint = (int)NormalizeDouble((MathAbs(currSymbolTick - Close[0]) / _Point), 0);
      
      /* Calculate previous divergence for comparison
       * lastKairi = previous tick divergence between symbols
       * Used to determine if divergence is increasing or decreasing
       */
      int lastKairi = (int)NormalizeDouble((MathAbs(lastSymbolTick - lastTick) / _Point), 0);
       
      // === CONVERGENCE EXIT CHECK ===
      
      /* Settlement when symbols converge (divergence closes)
       * If we have open positions (lastNumber > 0) and current divergence
       * drops below the exit threshold, close all positions
       */
      if (lastNumber > 0 && 
            kairiPoint <= exitKairi) {
            Print(__LINE__, "Settlement due to convergence (Divergence Point)");
            Print(__LINE__, " ", _Symbol, " Current value: ", DoubleToStr(Close[0], _Digits));
            Print(__LINE__, " ", JJ1, " Current value: ", DoubleToStr(currSymbolTick, _Digits));
            Print(__LINE__, " Divergence point: ", IntegerToString(kairiPoint));
            SendClose();  // Close all open positions
      }
       
      // === INDIVIDUAL POSITION EXIT CHECK ===
      
      // Check if individual entry levels have reached their profit targets
      CheckExit();
       
      // === STRATEGY RESET CHECK ===
      
      /* Reset trading state when all positions are closed
       * Count current open buy and sell positions
       * If no positions remain open, reset the entry level counter
       */
      int buyPos = 0,
          sellPos = 0;
      GetPos(buyPos, sellPos);  // Count current positions
      if (buyPos <= 0 && sellPos <= 0 && lastNumber > 0) {
            Print(__LINE__, "All positions closed -> Data reset");
            lastNumber = 0;  // Reset to allow new trading cycle
      }
       
      // === ENTRY CONDITION CHECKS ===
      
      /* Primary Entry Condition: Primary Symbol < Overlay Symbol
       * This triggers when the primary chart symbol trades below the overlay symbol
       * Action: BUY primary symbol, SELL overlay symbol
       * Logic: Expecting mean reversion - primary will rise, overlay will fall
       */
      if (NormalizeDouble(lastSymbolTick, _Digits) > 0 &&              // Previous overlay price valid
          NormalizeDouble(currSymbolTick, _Digits) > 0 &&              // Current overlay price valid
          NormalizeDouble(Close[0], _Digits) < NormalizeDouble(currSymbolTick, _Digits) &&  // Primary < Overlay
          lastNumber <= 10 &&                                           // Haven't exceeded maximum entry levels
          lastKairi < kairi[lastNumber] &&                             // Previous divergence was below threshold
          kairiPoint >= kairi[lastNumber]) {                           // Current divergence exceeds threshold
            
            Print(__LINE__, "Entry (Chart bought, overlay sold), ", IntegerToString(lastNumber + 1), "th time");
            Print(__LINE__, " ", _Symbol, " Current value: ", DoubleToStr(Close[0], _Digits));
            Print(__LINE__, " ", JJ1, " Current value: ", DoubleToStr(currSymbolTick, _Digits));
            Print(__LINE__, " Divergence point: ", IntegerToString(kairiPoint), " (", kairi[lastNumber], ")");
            
            // Execute pair trade: BUY primary, SELL overlay
            SendOrder(_Symbol, true, lots[lastNumber], magicNumber, slippage, ordertryMax, IntegerToString(lastNumber + 1), buyColor);
            SendOrder(JJ1, false, lots[lastNumber], magicNumber, slippage, ordertryMax, IntegerToString(lastNumber + 1), sellColor);
            lastNumber++;  // Move to next entry level
            
            // Check for additional entry levels that can be triggered immediately
            for (int i = lastNumber; i <= 10 && !IsStopped(); i++) {
                  if (lastKairi < kairi[lastNumber] && 
                        kairiPoint >= kairi[lastNumber]) {
                        Print(__LINE__, "Divergence point: ", IntegerToString(kairiPoint), " (", kairi[lastNumber], ")");
                        SendOrder(_Symbol, true, lots[lastNumber], magicNumber, slippage, ordertryMax, IntegerToString(lastNumber + 1), buyColor);
                        SendOrder(JJ1, false, lots[lastNumber], magicNumber, slippage, ordertryMax, IntegerToString(lastNumber + 1), sellColor);
                        lastNumber++;
                  }
                  else {
                        break;  // Stop if next level threshold not met
                  }
            }
      }
      
      /* Secondary Entry Condition: Primary Symbol > Overlay Symbol  
       * This triggers when the primary chart symbol trades above the overlay symbol
       * Action: SELL primary symbol, BUY overlay symbol
       * Logic: Expecting mean reversion - primary will fall, overlay will rise
       */
      else if (NormalizeDouble(lastSymbolTick, _Digits) > 0 &&         // Previous overlay price valid
               NormalizeDouble(currSymbolTick, _Digits) > 0 &&         // Current overlay price valid
               NormalizeDouble(Close[0], _Digits) > NormalizeDouble(currSymbolTick, _Digits) &&  // Primary > Overlay
               lastNumber <= 10 &&                                      // Haven't exceeded maximum entry levels
               lastKairi < kairi[lastNumber] &&                        // Previous divergence was below threshold
               kairiPoint >= kairi[lastNumber]) {                      // Current divergence exceeds threshold
            
            Print(__LINE__, " Entry (chart sold, overlay bought), ", IntegerToString(lastNumber + 1), "th time");
            Print(__LINE__, " ", _Symbol, " Current value: ", DoubleToStr(Close[0], _Digits));
            Print(__LINE__, " ", JJ1, " Current value: ", DoubleToStr(currSymbolTick, _Digits));
            Print(__LINE__, "Divergence point: ", IntegerToString(kairiPoint), " (", kairi[lastNumber], ")");
            
            // Execute pair trade: SELL primary, BUY overlay
            SendOrder(_Symbol, false, lots[lastNumber], magicNumber, slippage, ordertryMax, IntegerToString(lastNumber + 1), sellColor);
            SendOrder(JJ1, true, lots[lastNumber], magicNumber, slippage, ordertryMax, IntegerToString(lastNumber + 1), buyColor);
            lastNumber++;  // Move to next entry level
            
            // Check for additional entry levels that can be triggered immediately
            for (int i = lastNumber; i <= 10 && !IsStopped(); i++) {
                  if (lastKairi < kairi[lastNumber] && 
                        kairiPoint >= kairi[lastNumber]) {
                        Print(__LINE__, "Divergence point: ", IntegerToString(kairiPoint), " (", kairi[lastNumber], ")");
                        SendOrder(_Symbol, false, lots[lastNumber], magicNumber, slippage, ordertryMax, IntegerToString(lastNumber + 1), sellColor);
                        SendOrder(JJ1, true, lots[lastNumber], magicNumber, slippage, ordertryMax, IntegerToString(lastNumber + 1), buyColor);
                        lastNumber++;
                  }
                  else {
                        break;  // Stop if next level threshold not met
                  }
            }
      }
       
      // === UPDATE TRACKING VARIABLES ===
      
      // Store current prices for next tick comparison
      lastSymbolTick = currSymbolTick;     // Update overlay symbol price
      lastTick = Close[0];                 // Update primary symbol price
      
      // === DISPLAY STATUS INFORMATION ===
      
      /* Update chart comment with current trading status
       * Shows current prices and entry level information
       */
      Comment("\\n\\n\\n", _Symbol, " : ", DoubleToStr(Close[0], _Digits),
                    "\\n", JJ1, " : ", DoubleToStr(currSymbolTick, _Digits),
                    "\\n", IntegerToString(lastNumber), "Up to entries have been made");
}

//+---------------------------------------------------------------------------+
//| Position Counter Function                                                 |
//| Counts open buy and sell positions for this EA                          |
//+---------------------------------------------------------------------------+

void GetPos(int &_buyPos,    // Reference to buy position counter
            int &_sellPos) { // Reference to sell position counter
      
      int buyPos = 0,        // Local buy position counter
          sellPos = 0;       // Local sell position counter
          
      // Loop through all open orders in the terminal
      for (int i = 0; i < OrdersTotal() && !IsStopped(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS))  // Select order by position
                  continue;                       // Skip if selection fails
            if (OrderMagicNumber() != magicNumber) // Skip orders not from this EA
                  continue;
            if (OrderSymbol() != _Symbol && OrderSymbol() != JJ1) // Skip other symbols
                  continue;
                  
            int type = OrderType();              // Get order type
            if (type == OP_BUY) {               // If it's a buy order
                  buyPos++;                     // Increment buy counter
                  int buyID = (int)StringToInteger(OrderComment()); // Get entry level from comment
            }
            else if (type == OP_SELL) {         // If it's a sell order  
                  sellPos++;                    // Increment sell counter
                  int sellID = (int)StringToInteger(OrderComment()); // Get entry level from comment
            }
      }
      _buyPos = buyPos;      // Return buy count via reference
      _sellPos = sellPos;    // Return sell count via reference
}

//+---------------------------------------------------------------------------+
//| Order Sending Function                                                    |
//| Handles the actual market order execution with error handling           |
//+---------------------------------------------------------------------------+

int SendOrder(const string _symbol,           // Symbol to trade
              const bool _isBuy,              // Direction: true=Buy, false=Sell  
              const double _lots,             // Lot size to trade
              const int _magicNumber,         // Magic number for identification
              const int _slippage,            // Maximum slippage allowed
              const int _retryMaxNumber,      // Maximum retry attempts
              const string _comment="",       // Order comment (entry level)
              const color _entryColor=clrNONE, // Chart marker color
              const double _stopLossPrice=0,  // Stop loss price (not used)
              const double _takeProfitPrice=0) { // Take profit price (not used)
              
      // Check if trading is allowed in terminal
      if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
            return false;
      // Check if automated trading is enabled  
      if (!MQLInfoInteger(MQL_TRADE_ALLOWED))
            return false;
       
      int retTicket = -1;    // Order ticket number (-1 = failed)
      double entryLots = _lots; // Working lot size variable
      
      // === LOT SIZE VALIDATION AND NORMALIZATION ===
      
      // Ensure lot size doesn't exceed maximum allowed
      if (MarketInfo(_symbol, MODE_MAXLOT) < entryLots) {
            entryLots = MarketInfo(_symbol, MODE_MAXLOT);
      }
      // Ensure lot size meets minimum requirement
      if (MarketInfo(_symbol, MODE_MINLOT) > entryLots) {
            entryLots = MarketInfo(_symbol, MODE_MINLOT);
      }
       
      // Normalize lot size to broker's lot step
      double lotstep = MarketInfo(_symbol, MODE_LOTSTEP);           // Get lot step (e.g., 0.01)
      int normalizeLot = (int)MathAbs(MathLog10(lotstep));         // Calculate decimal places
      entryLots = MathFloor(entryLots * MathPow(10, normalizeLot)) * MathPow(0.1, normalizeLot); // Round to valid lot size
       
      int digits = (int)MarketInfo(_symbol, MODE_DIGITS);          // Get price decimal places
       
      // === ORDER EXECUTION WITH RETRY LOGIC ===
      
      // Attempt order placement with retry mechanism
      for (int i = 1; i <= _retryMaxNumber; i++) {
            RefreshRates();                  // Update price quotes
            ResetLastError();                // Clear any previous errors
            
            // Get current market price based on order direction
            double entryPrice = _isBuy ? NormalizeDouble(MarketInfo(_symbol, MODE_ASK), digits) 
                                      : NormalizeDouble(MarketInfo(_symbol, MODE_BID), digits);
                                      
            // Calculate stop loss if specified (currently not used)
            double  stopLoss = 0;
            if (_stopLossPrice > 0)
                  stopLoss = _isBuy ? NormalizeDouble(entryPrice - _stopLossPrice, digits) 
                                   : NormalizeDouble(entryPrice + _stopLossPrice, digits);
                                   
            // Calculate take profit if specified (currently not used)
            double takeProfit = 0;
            if (_takeProfitPrice > 0)
                  takeProfit = _isBuy ? NormalizeDouble(entryPrice + _takeProfitPrice, digits) 
                                     : NormalizeDouble(entryPrice - _takeProfitPrice, digits);
                                     
            // Determine order type
            int entryType = _isBuy ? OP_BUY : OP_SELL;
            
            // Send the market order
            retTicket = OrderSend(_symbol, entryType, entryLots, entryPrice, _slippage, 
                                stopLoss, takeProfit, _comment, _magicNumber, 0, _entryColor);
                                
            // === ERROR HANDLING ===
            
            if (retTicket == -1) {           // Order failed
                  int errorCode = GetLastError();
                  if (errorCode != ERR_NO_ERROR) {
                        Print(__LINE__, "Order error [" + IntegerToString(i) + " attempt] error code: " + IntegerToString(errorCode) + " Details: " + ErrorDescription(errorCode));
                        
                        // Handle critical errors that shouldn't be retried
                        if (errorCode == ERR_TRADE_NOT_ALLOWED)
                              return retTicket;
                        if (errorCode == ERR_LONGS_NOT_ALLOWED)
                              return retTicket;
                        if (errorCode == ERR_SHORTS_NOT_ALLOWED)
                              return retTicket;
                        if (errorCode == ERR_NOT_ENOUGH_MONEY)
                              return retTicket;
                  }

                  Sleep(1000);               // Wait before retry
                  RefreshRates();            // Update quotes
                  continue;                  // Try again
            } else {                        // Order successful
                  Print(__LINE__, "New Order Success Ticket No = " + IntegerToString(retTicket));
                  Sleep(300);                // Brief pause after successful order
                  return retTicket;          // Return ticket number
            }
      }
      return retTicket;                     // Return final result (likely -1 if all retries failed)
}

//+---------------------------------------------------------------------------+
//| Position Closing Function - Close Specific Entry Level                   |
//| Closes all positions belonging to a specific entry level number         |
//+---------------------------------------------------------------------------+

bool SendClose(const int _exitNumber) {    // Entry level number to close
       
      // Check if trading is allowed
      if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
            return false;
      if (!MQLInfoInteger(MQL_TRADE_ALLOWED))
            return false;
       
      bool returnClose = true;              // Overall success flag
      
      // Loop through orders from newest to oldest (reverse order for safe closing)
      for (int i = OrdersTotal() - 1; i >= 0 && !IsStopped(); i--) {
            if (!OrderSelect(i, SELECT_BY_POS))  // Select order
                  continue;
            if (OrderCloseTime() > 0)         // Skip already closed orders
                  continue;
            if (OrderMagicNumber() != magicNumber) // Skip other EA's orders
                  continue;
            if (OrderSymbol() != _Symbol && OrderSymbol() != JJ1) // Skip other symbols
                  continue;
             
            int type = OrderType();           // Get order type
            if (type != OP_BUY && type != OP_SELL) // Only handle market orders
                  continue;
             
            // Check if this order belongs to the specified entry level
            string comment = OrderComment();
            int number = (int)StringToInteger(comment);
            if (number != _exitNumber)        // Skip orders from other entry levels
                  continue;
             
            // === CLOSE ORDER WITH RETRY LOGIC ===
            
            bool retClose = false;            // Individual order close success
            for (int closeIndex = 1; closeIndex <= ordertryMax; closeIndex++) {
                  RefreshRates();             // Update quotes
                  ResetLastError();           // Clear errors
                  
                  int orderTicket = OrderTicket();    // Get order ticket
                  int digits = (int)MarketInfo(OrderSymbol(), MODE_DIGITS); // Get symbol digits
                  
                  // Get appropriate closing price (opposite of opening)
                  double closePrice = OrderType() == OP_BUY ? NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID), digits)
                                                            : NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK), digits);
                                                            
                  // Attempt to close the order
                  retClose = OrderClose(orderTicket, OrderLots(), closePrice, slippage, closeColor);
                  
                  if (!retClose) {            // Close failed
                        int errorCode = GetLastError();
                        if (errorCode != ERR_NO_ERROR) {
                              Print(__LINE__, " Close error [" + IntegerToString(closeIndex) + " attempt] error code: " + IntegerToString(errorCode) + " Details: " + ErrorDescription(errorCode));
                              
                              // Handle critical errors
                              if (errorCode == ERR_TRADE_NOT_ALLOWED)
                                    return false;
                              if (errorCode == ERR_LONGS_NOT_ALLOWED)
                                    return false;
                              if (errorCode == ERR_SHORTS_NOT_ALLOWED)
                                    return false;
                        }

                        Sleep(1000);          // Wait before retry
                  }
                  else {                      // Close successful
                        Print(__LINE__, " Close Order Success Ticket No = " + IntegerToString(orderTicket));
                        Sleep(300);           // Brief pause
                        break;                // Exit retry loop
                  }
            }
            if (!retClose)                    // If this order failed to close
                  returnClose = false;        // Mark overall operation as failed
      }
      return returnClose;                     // Return overall success status
}

//+---------------------------------------------------------------------------+
//| Position Closing Function - Close All Positions                         |
//| Closes all positions opened by this EA (used for convergence exit)      |
//+---------------------------------------------------------------------------+

bool SendClose(void) {
       
      // Check if trading is allowed
      if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
            return false;
      if (!MQLInfoInteger(MQL_TRADE_ALLOWED))
            return false;
       
      bool returnClose = true;              // Overall success flag
      
      // Loop through orders from newest to oldest (reverse order for safe closing)
      for (int i = OrdersTotal() - 1; i >= 0 && !IsStopped(); i--) {
            if (!OrderSelect(i, SELECT_BY_POS))  // Select order
                  continue;
            if (OrderCloseTime() > 0)         // Skip already closed orders
                  continue;
            if (OrderMagicNumber() != magicNumber) // Skip other EA's orders
                  continue;
            if (OrderSymbol() != _Symbol && OrderSymbol() != JJ1) // Skip other symbols
                  continue;
             
            int type = OrderType();           // Get order type
            if (type != OP_BUY && type != OP_SELL) // Only handle market orders
                  continue;
             
            // === CLOSE ORDER WITH RETRY LOGIC ===
            
            bool retClose = false;            // Individual order close success
            for (int closeIndex = 1; closeIndex <= ordertryMax; closeIndex++) {
                  RefreshRates();             // Update quotes
                  ResetLastError();           // Clear errors
                  
                  int orderTicket = OrderTicket();    // Get order ticket
                  int digits = (int)MarketInfo(OrderSymbol(), MODE_DIGITS); // Get symbol digits
                  
                  // Get appropriate closing price (opposite of opening)
                  double closePrice = OrderType() == OP_BUY ? NormalizeDouble(MarketInfo(OrderSymbol(), MODE_BID), digits)
                                                            : NormalizeDouble(MarketInfo(OrderSymbol(), MODE_ASK), digits);
                                                            
                  // Attempt to close the order
                  retClose = OrderClose(orderTicket, OrderLots(), closePrice, slippage, closeColor);
                  
                  if (!retClose) {            // Close failed
                        int errorCode = GetLastError();
                        if (errorCode != ERR_NO_ERROR) {
                              Print(__LINE__, "Close error [" + IntegerToString(closeIndex) + " attempt] error code: " + IntegerToString(errorCode) + " Details: " + ErrorDescription(errorCode));
                              
                              // Handle critical errors
                              if (errorCode == ERR_TRADE_NOT_ALLOWED)
                                    return false;
                              if (errorCode == ERR_LONGS_NOT_ALLOWED)
                                    return false;
                              if (errorCode == ERR_SHORTS_NOT_ALLOWED)
                                    return false;
                        }

                        Sleep(1000);          // Wait before retry
                  }
                  else {                      // Close successful
                        Print(__LINE__, " Close Order Success Ticket No = " + IntegerToString(orderTicket));
                        Sleep(300);           // Brief pause
                        break;                // Exit retry loop
                  }
            }
            if (!retClose)                    // If this order failed to close
                  returnClose = false;        // Mark overall operation as failed
      }
      return returnClose;                     // Return overall success status
}

//+---------------------------------------------------------------------------+
//| Individual Profit Target Check Function                                  |
//| Monitors each entry level's profit and closes when target is reached    |
//+---------------------------------------------------------------------------+

void CheckExit(void) {
      double profit[11];                    // Array to store profit for each entry level
      ArrayInitialize(profit, 0);           // Initialize all elements to 0
       
      // === CALCULATE PROFIT BY ENTRY LEVEL ===
      
      // Loop through all open positions and accumulate profit by entry level
      for (int i = OrdersTotal() - 1; i >= 0 && !IsStopped(); i--) {
            if (!OrderSelect(i, SELECT_BY_POS))  // Select order
                  continue;
            if (OrderCloseTime() > 0)         // Skip closed orders
                  continue;
            if (OrderMagicNumber() != magicNumber) // Skip other EA's orders
                  continue;
            if (OrderSymbol() != _Symbol && OrderSymbol() != JJ1) // Skip other symbols
                  continue;
             
            // Extract entry level number from order comment
            string comment = OrderComment();
            int number = (int)StringToInteger(comment);
             
            // Accumulate total profit/loss for this entry level
            if (number > 0) {                 // Valid entry level number
                  profit[number - 1] += OrderProfit();     // Add trading profit/loss
                  profit[number - 1] += OrderCommission();  // Add commission cost
                  profit[number - 1] += OrderSwap();       // Add swap cost/credit
            }
      }
       
      // === CHECK PROFIT TARGETS ===
      
      // Check each entry level against its profit target
      for (int i = 0; i < 11 && !IsStopped(); i++) {
            // If profit for this level meets or exceeds target
            if (NormalizeDouble(profit[i], 3) >= NormalizeDouble(TP[i], 3)) {
                  Print(__LINE__, " Individual close (profit target reached)");
                  Print(__LINE__, " ", IntegerToString(i + 1), " entry level");
                  Print(__LINE__, " Total P&L: ", DoubleToString(profit[i], 3), " , Target: ", DoubleToString(TP[i], 3));
                  SendClose(i + 1);          // Close all positions for this entry level
            }
      }
}

//+---------------------------------------------------------------------------+
//| END OF EXPERT ADVISOR CODE                                               |
//+---------------------------------------------------------------------------+
/*
 * TRADING STRATEGY SUMMARY:
 * ========================
 * 
 * This EA implements a sophisticated pair trading strategy:
 * 
 * 1. DIVERGENCE MONITORING: Continuously monitors price difference between
 *    primary chart symbol and overlay symbol (JJ1)
 * 
 * 2. ESCALATING ENTRIES: Uses 11 progressively wider divergence levels
 *    (200, 250, 300... up to 700 points) to scale into positions
 * 
 * 3. PAIR TRADING LOGIC: 
 *    - When primary < overlay: BUY primary, SELL overlay
 *    - When primary > overlay: SELL primary, BUY overlay
 * 
 * 4. MULTIPLE EXIT CONDITIONS:
 *    - Convergence exit: Close all when divergence drops below 100 points
 *    - Individual profit targets: Close specific levels when TP reached
 * 
 * 5. RISK MANAGEMENT:
 *    - Magic number isolation
 *    - Lot size validation  
 *    - Order retry mechanisms
 *    - Time and account restrictions
 * 
 * IMPORTANT CONSIDERATIONS:
 * - Requires custom overlay indicator for price data
 * - High-risk martingale-style position scaling
 * - No stop losses implemented
 * - Time-limited functionality (2023 restriction)
 * - Designed for highly correlated currency pairs
 * 
 * USE WITH CAUTION: This strategy can result in significant losses
 * if correlation between symbols breaks down permanently.
 */