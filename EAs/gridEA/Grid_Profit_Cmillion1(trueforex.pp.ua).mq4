//+------------------------------------------------------------------+
//|                               Copyright � 2013, Vladimir Hlystov |
//|    ��������� ��� ������ ��� ������������ �������                 |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2013, http://cmillion.narod.ru"
#property link      "cmillion@narod.ru"
//--------------------------------------------------------------------
extern datetime TimeSet        = D'2011.12.10 17:47'; //����� ����������� �������, ���� ������� ����� ������ ��������������, �� ������������ �����
extern bool     SELL_Stop      = true;     //
extern bool     BUY_Stop       = true;     //
extern bool     SELL_Limit     = true;     //
extern bool     BUY_Limit      = true;     //Y
extern string   __             = "";
extern double   FirstBuyStop   = 0;        //���� ����������� ������� BuyStop ������, ���� 0 �� ������ BuyStop ����� ��������� �� ���� Ask+FirstStop
extern double   FirstSellStop  = 0;        //���� ����������� ������� SellStop ������, ���� 0 �� ������ SellStop ����� ��������� �� ���� Bid-FirstStop
extern double   FirstBuyLimit  = 0;        //���� ����������� ������� BuyLimit ������, ���� 0 �� ������ BuyLimit ����� ��������� �� ���� Bid-FirstStop
extern double   FirstSellLimit = 0;        //���� ����������� ������� SellLimit ������, ���� 0 �� ������ SellLimit ����� ��������� �� ���� Ask+FirstStop
extern int      FirstStop      = 100;      //���������� (� �������) �� ������� ���� �� ������� Stop ������ � ������ First..Stop=0 
extern int      FirstLimit     = 50;       //���������� (� �������) �� ������� ���� �� ������� Limit ������ � ������ First..Limit=0
extern int      StepStop       = 30;       //���������� (� �������) ����� Stop ��������
extern double   K_StepStop     = 1;        //����������� ���������� �����
extern int      StepLimit      = 30;       //���������� (� �������) ����� Limit ��������
extern double   K_StepLimit    = 1;        //����������� ���������� �����
extern string   _              = "";
extern int      Orders         = 5;        //���-�� ������� �����
extern double   LotStop        = 0.5;      //����� ������� Stop ������
extern double   K_LotStop      = 1;        //��������� ���� Stop ������� 
extern double   Plus_LotStop   = 0;        //���������� ���� Stop ������� 
extern double   LotLimit       = 0.1;      //����� ������� Limit ������
extern double   K_LotLimit     = 2;        //��������� ���� Limit �������
extern double   Plus_LotLimit  = 0;        //���������� ���� Limit �������
extern int      stoploss       = 50;       //������� ����������� SL, ���� 0, �� SL �� ������������
extern int      takeprofit     = 100;      //������� ����������� TP, ���� 0, �� TP �� ������������
extern int      Expiration     = 1440;     //���� ��������� ����������� ������ � �������, ���� 0, �� ���� �� ��������� (1440 - �����)
extern int      attempts       = 10;       //���-�� ������� �������� ������ 
extern int      Magic          = 0;        //���������� ����� ������
//--------------------------------------------------------------------
string txt;
int n,slippage=3,STOPLEVEL;
datetime expiration;
//--------------------------------------------------------------------
//-------------------------------------------------------------------
extern double ProfitClose     = 10;   //��������� ��� ������ ��� ��������� ������� � ������ ��������
extern double LossClose       = 1000; //��������� ��� ������ ��� ��������� ������
extern bool   AllSymbol       = false;//��������� ��� ����������� ��� ������ ���, �� ������� ����� ��������
//extern int    Magic           = 0;    //0 - ��������� ��� ������ (� ����� Magic �������)
//-------------------------------------------------------------------
//string txt;
int init()
{
   ObjectCreate("Balance", OBJ_LABEL, 0, 0, 0);
   ObjectSet("Balance", OBJPROP_CORNER, 1);
   ObjectSet("Balance", OBJPROP_XDISTANCE, 5);
   ObjectSet("Balance", OBJPROP_YDISTANCE, 15);
   ObjectCreate("Equity", OBJ_LABEL, 0, 0, 0);
   ObjectSet("Equity", OBJPROP_CORNER, 1);
   ObjectSet("Equity", OBJPROP_XDISTANCE, 5);
   ObjectSet("Equity", OBJPROP_YDISTANCE, 25);
   ObjectCreate("Profit", OBJ_LABEL, 0, 0, 0);
   ObjectSet("Profit", OBJPROP_CORNER, 1);
   ObjectSet("Profit", OBJPROP_XDISTANCE, 5);
   ObjectSet("Profit", OBJPROP_YDISTANCE, 35);
   ObjectCreate("Copyright", OBJ_LABEL, 0, 0, 0);
   ObjectSet("Copyright", OBJPROP_CORNER, 3);
   ObjectSet("Copyright", OBJPROP_XDISTANCE, 5);
   ObjectSet("Copyright", OBJPROP_YDISTANCE, 5);
   ObjectSetText("Copyright","CloseProfit Copyright � 2013, http://cmillion.narod.ru\n",8,"Arial",Gold);
   if (AllSymbol) txt = "�� ���� ������������ �����";
   if (Magic==0) txt = StringConcatenate(txt,"\n�� ���� Magic");
   txt = StringConcatenate(txt,"\n�� Magic = ",Magic);
   return(0);
}
//-------------------------------------------------------------------
int deinit()
{
   ObjectDelete("Balance");
   ObjectDelete("Equity");
   ObjectDelete("Profit");
   ObjectDelete("Copyright");
   return(0);
}
//-------------------------------------------------------------------
int start()
{
   OpenGrid();
   double Profit,LB,LS,OL;
   int b,s,OT;
   for (int i=OrdersTotal()-1; i>=0; i--)
   {                                               
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if ((OrderSymbol() == Symbol() || AllSymbol) && (Magic==0 || Magic==OrderMagicNumber()))
         {
            OT = OrderType();
            OL = OrderLots();
            Profit+=OrderProfit()+OrderCommission()+OrderSwap();
            if (OT==OP_BUY)
            {
               b++;LB+= OL;
            }
            if (OT==OP_SELL)
            {
               s++;LS+= OL;
            }
         }
      }
   }
   Comment(txt,"\nBuy ",b,"\nSell ",s);
   //--- 
   if (Profit>=ProfitClose) 
   {
      Alert("��������� ������� ������� = "+DoubleToStr(Profit,2));
      CloseAll();
   }
   if (Profit<=-LossClose)
   {
      Alert("��������� ������� ������������� ������ "+DoubleToStr(Profit,2));
      CloseAll();
   }
   ObjectSetText("Balance",StringConcatenate("Balance ",DoubleToStr(AccountBalance(),2)),8,"Arial",Gold);
   ObjectSetText("Equity",StringConcatenate("Equity ",DoubleToStr(AccountEquity(),2)),8,"Arial",Gold);

   string txt2;
   if (LB>0 || LS>0) 
   {
      if (AllSymbol) txt2 = StringConcatenate("Profit All Symbol ",DoubleToStr(Profit,2));
      else           txt2 = StringConcatenate("Profit ",Symbol()," ",DoubleToStr(Profit,2));
   }
   if (LB>0) txt2 = StringConcatenate(txt2,"  Lot Buy = ",DoubleToStr(LB,2));
   if (LS>0) txt2 = StringConcatenate(txt2,"  Lot Sell = ",DoubleToStr(LS,2));
   ObjectSetText("Profit",txt2,12,"Arial",Color(Profit));

return;
}
//------------------------------------------------------------------
color Color(double P)
{
   if (P>0) return(Green);
   if (P<0) return(Red);
   if (P==0) return(Green);
}
//------------------------------------------------------------------
bool CloseAll()
{
   bool error=true;
   int err,nn,OT;
   string Symb;
   while(true)
   {
      for (int j = OrdersTotal()-1; j >= 0; j--)
      {
         if (OrderSelect(j, SELECT_BY_POS))
         {
            Symb = OrderSymbol();
            if ((Symb == Symbol() || AllSymbol) && (Magic==0 || Magic==OrderMagicNumber()))
            {
               OT = OrderType();
               if (OT>1) 
               {
                  OrderDelete(OrderTicket());
               }
               if (OT==OP_BUY) 
               {
                  error=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(MarketInfo(Symb,MODE_BID),MarketInfo(Symb,MODE_DIGITS)),3,Blue);
                  if (error) Alert(Symb,"  ������ ����� N ",OrderTicket(),"  ������� ",OrderProfit(),
                                     "     ",TimeToStr(TimeCurrent(),TIME_SECONDS));
               }
               if (OT==OP_SELL) 
               {
                  error=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(MarketInfo(Symb,MODE_ASK),MarketInfo(Symb,MODE_DIGITS)),3,Red);
                  if (error) Alert(Symb,"  ������ ����� N ",OrderTicket(),"  ������� ",OrderProfit(),
                                     "     ",TimeToStr(TimeCurrent(),TIME_SECONDS));
               }
               if (!error) 
               {
                  err = GetLastError();
                  if (err<2) continue;
                  if (err==129) 
                  {  Comment("������������ ���� ",TimeToStr(TimeCurrent(),TIME_MINUTES));
                     Sleep(5000);
                     RefreshRates();
                     continue;
                  }
                  if (err==146) 
                  {
                     if (IsTradeContextBusy()) Sleep(2000);
                     continue;
                  }
                  Comment("������ ",err," �������� ������ N ",OrderTicket(),
                          "     ",TimeToStr(TimeCurrent(),TIME_MINUTES));
               }
            }
         }
      }
      int n=0;
      for (j = 0; j < OrdersTotal(); j++)
      {
         if (OrderSelect(j, SELECT_BY_POS))
         {
            if ((OrderSymbol() == Symbol() || AllSymbol) && (Magic==0 || Magic==OrderMagicNumber()))
            {
               OT = OrderType();
               if (OT==OP_BUY || OT==OP_SELL) n++;
            }
         }  
      }
      if (n==0) break;
      nn++;
      if (nn>10) {Alert(Symb,"  �� ������� ������� ��� ������, �������� ��� ",n);return(0);}
      Sleep(1000);
      RefreshRates();
   }
   return(1);
}
//--------------------------------------------------------------------
void OpenGrid()
{
//===========================================================================================================================================   
//===========================================================================================================================================   
//===========================================================================================================================================   
/*============================================*/if (IsTesting() && OrdersTotal()>0) return;/*===============================================*/
//===========================================================================================================================================   
//===========================================================================================================================================   
//===========================================================================================================================================   
   if (Expiration>0) expiration=TimeCurrent()+Expiration*60; else expiration=0;
   Comment("������ ������� OpenStopOrderNetTime ",TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS));
   STOPLEVEL=MarketInfo(Symbol(),MODE_STOPLEVEL);
   if (Digits==3 || Digits==5) slippage=30;
   while (TimeCurrent()<TimeSet)
   {
      Sleep(1000);
      Comment("������ ����������� ����� ���������� ������� Copyright � 2013 cmillion@narod.ru\n",
      TimeToStr(TimeCurrent(),TIME_SECONDS)," �� ����������� ����� �������� ",TimeToStr(TimeSet-TimeCurrent(),TIME_SECONDS));
      RefreshRates();
   }
   double PriceBS,PriceBL,PriceSS,PriceSL;
   double LOTs=LotStop;
   double LOTl=LotLimit;
   if (BUY_Stop)
   {
      if (FirstBuyStop==0) PriceBS = NormalizeDouble(Ask+FirstStop*Point,Digits);
      else PriceBS = NormalizeDouble(FirstBuyStop,Digits);
      if ((PriceBS-Ask)/Point<STOPLEVEL) {Alert("������ ����� BuyStop �� ����� ���� ���������� ����� ��� ",STOPLEVEL," �");return;}
   }
   if (SELL_Stop)
   {
      if (FirstSellStop==0) PriceSS = NormalizeDouble(Bid-FirstStop*Point,Digits);
      else PriceSS = NormalizeDouble(FirstSellStop,Digits);
      if ((Bid-PriceSS)/Point<STOPLEVEL) {Alert("������ ����� SellStop �� ����� ���� ���������� ����� ��� ",STOPLEVEL," �");return;}
   }
   if (BUY_Limit)
   {
      if (FirstBuyLimit==0) PriceBL = NormalizeDouble(Bid-FirstLimit*Point,Digits);
      else PriceBL = NormalizeDouble(FirstBuyLimit,Digits);
      if ((Bid-PriceBL)/Point<STOPLEVEL) {Alert("������ ����� BuyLimit �� ����� ���� ���������� ����� ��� ",STOPLEVEL," �");return;}
   }
   if (SELL_Limit)
   {
      if (FirstSellLimit==0) PriceSL = NormalizeDouble(Ask+FirstLimit*Point,Digits);
      else PriceSL = NormalizeDouble(FirstSellLimit,Digits);
      if ((PriceSL-Ask)/Point<STOPLEVEL) {Alert("������ ����� SellLimit �� ����� ���� ���������� ����� ��� ",STOPLEVEL," �");return;}
   }
   double Step_Stop=StepStop;
   double Step_Limit=StepLimit;
   for (int i=1; i<=Orders; i++)
   {
      Step_Stop=Step_Stop*K_StepStop;
      if (BUY_Stop)
      {
         OPENORDER (OP_BUYSTOP,PriceBS,LOTs,i);
         PriceBS = NormalizeDouble(PriceBS+Step_Stop*Point,Digits);
      }
      if (SELL_Stop)
      {  
         OPENORDER (OP_SELLSTOP,PriceSS,LOTs,i);
         PriceSS = NormalizeDouble(PriceSS-Step_Stop*Point,Digits);
      }
      LOTs=LOTs*K_LotStop+Plus_LotStop;
      Step_Limit=Step_Limit*K_StepLimit;
      if (BUY_Limit)
      {
         OPENORDER (OP_BUYLIMIT,PriceBL,LOTl,i);
         PriceBL = NormalizeDouble(PriceBL-Step_Limit*Point,Digits);
      }
      if (SELL_Limit)
      {  
         OPENORDER (OP_SELLLIMIT,PriceSL,LOTl,i);
         PriceSL = NormalizeDouble(PriceSL+Step_Limit*Point,Digits);
      }
      LOTl=LOTl*K_LotLimit+Plus_LotLimit;
   }
   Comment("������ �������� ���� ������, ���������� ",n," �������  ",TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS));
return(0);
}
//--------------------------------------------------------------------
void OPENORDER(int ord,double Price,double LOT,int i)
{
   int error,err;
   double SL,TP;
   while (true)
   {  error=true;
      if (ord==OP_BUYSTOP) 
      {
         if (takeprofit!=0) TP  = NormalizeDouble(Price + takeprofit*Point,Digits); else TP=0;
         if (stoploss!=0)   SL  = NormalizeDouble(Price - stoploss*Point,Digits); else SL=0;     
         error=OrderSend(Symbol(),ord, LOT,Price,slippage,SL,TP,"http://cmillion.narod.ru",Magic,expiration,Blue);
      }
      if (ord==OP_SELLSTOP) 
      {
         if (takeprofit!=0) TP = NormalizeDouble(Price - takeprofit*Point,Digits); else TP=0;
         if (stoploss!=0)   SL = NormalizeDouble(Price + stoploss*Point,Digits);  else SL=0;              
         error=OrderSend(Symbol(),ord,LOT,Price,slippage,SL,TP,"http://cmillion.narod.ru",Magic,expiration,Red);
      }
      if (ord==OP_SELLLIMIT) 
      {
         if (takeprofit!=0) TP = NormalizeDouble(Price - takeprofit*Point,Digits); else TP=0;
         if (stoploss!=0)   SL = NormalizeDouble(Price + stoploss*Point,Digits);  else SL=0;              
         error=OrderSend(Symbol(),ord, LOT,Price,slippage,SL,TP,"http://cmillion.narod.ru",Magic,expiration,Blue);
      }
      if (ord==OP_BUYLIMIT) 
      {
         if (takeprofit!=0) TP  = NormalizeDouble(Price + takeprofit*Point,Digits); else TP=0;
         if (stoploss!=0)   SL  = NormalizeDouble(Price - stoploss*Point,Digits); else SL=0;     
         error=OrderSend(Symbol(),ord,LOT,Price,slippage,SL,TP,"http://cmillion.narod.ru",Magic,expiration,Red);
      }
      if (error==-1)
      {  
         txt=StringConcatenate(txt,"\nError ",GetLastError());
         if (ord==OP_BUYSTOP)   txt = StringConcatenate(txt,"  OPENORDER BUYSTOP ",  i,"   Ask =",DoubleToStr(Ask,Digits),"   Price =",DoubleToStr(Price,Digits)," (",NormalizeDouble((Price-Ask)/Point,0),")  SL =",DoubleToStr(SL,Digits)," (",NormalizeDouble((Price-SL)/Point,0),")  TP=",DoubleToStr(TP,Digits)," (",NormalizeDouble((TP-Price)/Point,0),")  STOPLEVEL=",STOPLEVEL);
         if (ord==OP_SELLSTOP)  txt = StringConcatenate(txt,"  OPENORDER SELLSTOP ", i,"   Bid =",DoubleToStr(Bid,Digits),"   Price =",DoubleToStr(Price,Digits)," (",NormalizeDouble((Bid-Price)/Point,0),")  SL =",DoubleToStr(SL,Digits)," (",NormalizeDouble((SL-Price)/Point,0),")  TP=",DoubleToStr(TP,Digits)," (",NormalizeDouble((Price-TP)/Point,0),")  STOPLEVEL=",STOPLEVEL);
         if (ord==OP_SELLLIMIT) txt = StringConcatenate(txt,"  OPENORDER SELLLIMIT ",i,"   Ask =",DoubleToStr(Ask,Digits),"   Price =",DoubleToStr(Price,Digits)," (",NormalizeDouble((Price-Ask)/Point,0),")  SL =",DoubleToStr(SL,Digits)," (",NormalizeDouble((Price-SL)/Point,0),")  TP=",DoubleToStr(TP,Digits)," (",NormalizeDouble((TP-Price)/Point,0),")  STOPLEVEL=",STOPLEVEL);
         if (ord==OP_BUYLIMIT)  txt = StringConcatenate(txt,"  OPENORDER BUYLIMIT ", i,"   Bid =",DoubleToStr(Bid,Digits),"   Price =",DoubleToStr(Price,Digits)," (",NormalizeDouble((Bid-Price)/Point,0),")  SL =",DoubleToStr(SL,Digits)," (",NormalizeDouble((SL-Price)/Point,0),")  TP=",DoubleToStr(TP,Digits)," (",NormalizeDouble((Price-TP)/Point,0),")  STOPLEVEL=",STOPLEVEL);
         Print(txt);
         Comment(txt,"  ",TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS));
         err++;Sleep(1000);RefreshRates();
      }
      else 
      {
         Comment("����� ",error," ������� ��������� ",TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS));
         n++;
         return;
      }
      if (err>attempts) return;
   }
return;
}                  
//--------------------------------------------------------------------

