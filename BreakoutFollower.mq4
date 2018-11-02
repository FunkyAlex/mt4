//+---------------------------------------------------------------------------------+
//|                                  BreakoutFollower.mq4                              |
//|                                  Copyright 2017, Alex Hutchinson                |
//|                                  http://www.alexhutchinson.info                 |
//|                                  version 1.0                                    |
//| positive pairs:                                                                 |
//|                                                                                 | 
//|                                                                                 |
//+---------------------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#define MAGICMA 1

double closeLast;

bool insideBarFlag = false;
double outsideHigh;
double outsideLow;
double minimumEntryPips;
double spread;
double high1;
double low1 ;
double high2;
double low2 ;

double EMA8;
double EMA21;

double close1;



// external variables =============================
extern int Slippage = 3;
//==================================================

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----

// -------------------------------------------

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
//if(IsVisualMode()==true){ IsTestingDelay(1); }

double Lots = AccountBalance()/10000;

high1 = iHigh(Symbol(), Period(),1);
low1 = iLow(Symbol(), Period(),1);

high2 = iHigh(Symbol(), Period(),2);
low2 = iLow(Symbol(), Period(),2);

close1 = iClose(Symbol(), Period(),1);

EMA8 = iMA(Symbol(),Period(),8,1,MODE_EMA,PRICE_CLOSE,1);
EMA21 = iMA(Symbol(),Period(),21,1,MODE_EMA,PRICE_CLOSE,1);


minimumEntryPips = MathAbs(NormalizeDouble(Ask-Bid,Digits)/Point) *3;
spread = MathAbs(NormalizeDouble(Ask-Bid,Digits)/Point);

bool Ea_TradeOpen = false;
bool Ea_Sell_On = false;
bool Ea_Buy_On = false;

int Ea_Ticket_Nbr = 0;
int total=OrdersTotal();

double Ea_Open_StopLoss = 0;



if (total > 0)
  {
  for(int pos=0;pos<total;pos++)
    {
    // detects if the robot already has a trade(s) in progress
     if(OrderSelect(pos,SELECT_BY_POS)==false) continue;
       if((OrderMagicNumber() == MAGICMA) && (OrderSymbol() == Symbol())) 
         {
         Ea_TradeOpen = true;
         if (OrderType() == 0) {Ea_Buy_On = true ; Ea_Sell_On = false;}
         if (OrderType() == 1) {Ea_Buy_On = false; Ea_Sell_On = true ;}
         Ea_Ticket_Nbr = OrderTicket();
    
  
         Ea_Open_StopLoss = OrderStopLoss();
         }
      }
    } 
if (insideBarFlag == false && high1 < high2 && low1 > low2)
{
   // inide bar is flagged
   insideBarFlag = true;
   outsideLow  = low2;
   outsideHigh = high2;

}

if (Ea_TradeOpen == false)// if no open positions - check for possible trade-------------------------------------
  {
 
  MathAbs(NormalizeDouble(outsideLow - close1,Digits)/Point);
 
  // Buy
  if ( insideBarFlag == true && close1 < outsideLow  )//&& MathAbs(NormalizeDouble(outsideLow - close1,Digits)/Point) > minimumEntryPips
  {
     
     double targetPipsSell = MathAbs(NormalizeDouble(outsideHigh - outsideLow,Digits)/Point); //+ (50*Point)
    
     //int ticketbuy = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,Ask - (stopLossPipsBuy*Point) ,outsideLow- NormalizeDouble(Ask-Bid,Digits),"Fader",MAGICMA,0,Green);
     int ticketsell2 = OrderSend(Symbol(),OP_SELLLIMIT,Lots,outsideLow - NormalizeDouble(Ask-Bid,Digits),Slippage,outsideLow + ((targetPipsSell/2)*Point) ,outsideLow - (targetPipsSell*Point),"Follower",MAGICMA,TimeCurrent()+14400,Red);
     if(ticketsell2 > 0)
     {
         insideBarFlag = false;
         outsideHigh = 0.00;
         outsideLow = 0.00;
     }

  }
  
  
  // Sell
  if ( insideBarFlag == true && close1 > outsideHigh  )//&& MathAbs(NormalizeDouble(close1 - outsideHigh,Digits)/Point) > minimumEntryPips
  {
      
      double targetPipsBuy = MathAbs(NormalizeDouble(outsideHigh - outsideLow,Digits)/Point) ;//+ (50*Point)
     
      //int ticketsell = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,Bid + (stopLossPipsSell*Point)  ,outsideHigh + NormalizeDouble(Ask-Bid,Digits),"Fader",MAGICMA,0,Red); 
      int ticketbuy2 = OrderSend(Symbol(),OP_BUYLIMIT,Lots,outsideHigh+ NormalizeDouble(Ask-Bid,Digits),Slippage,outsideHigh - ((targetPipsBuy/2)*Point) ,outsideHigh + (targetPipsBuy*Point),"Follower",MAGICMA,TimeCurrent()+14400,Green);
      if(ticketbuy2 > 0)
      {
         insideBarFlag = false;
         outsideHigh = 0.00;
         outsideLow = 0.00;
      }

  }
  
  }

    
Comment(

  "Inside bar flagged : " + insideBarFlag + "\n",
  "Outside high : " + outsideHigh + "\n",
  "Outside low : " + outsideLow + "\n"
  );
//----

   return(0);
  }
  
  
//+------------------------------------------------------------------+