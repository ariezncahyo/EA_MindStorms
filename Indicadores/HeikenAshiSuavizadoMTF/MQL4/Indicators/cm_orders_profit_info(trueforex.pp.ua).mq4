//+------------------------------------------------------------------+
//|                                        cm_orders_profit_info.mq4 |
//|                                Copyright 2014, cmillion@narod.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, cmillion@narod.ru"
#property link      "cmillion@narod.ru"
#property version   "1.00"
#property strict
#property indicator_chart_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   for(int j=0; j<OrdersTotal(); j++)
     {
      if(OrderSelect(j,SELECT_BY_POS))
        {
         if(Symbol()==OrderSymbol())
           {
            string name=IntegerToString(OrderTicket());
            ObjectDelete(0,name);
            TextCreate(0,name,0,Time[140],OrderOpenPrice(),StringConcatenate("",DoubleToStr(OrderSwap(),2)), "Arial",8,Color(OrderProfit()<0,clrPink,clrAqua));//"Magic = ",OrderMagicNumber(),"    Profit = ",DoubleToStr(OrderProfit(),2), 
           }
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TextCreate(const long              chart_ID=0,               // ID �������
                const string            name="Text",              // ��� �������
                const int               sub_window=0,             // ����� �������
                datetime                time=0,                   // ����� ����� ��������
                double                  price=0,                  // ���� ����� ��������
                const string            text="Text",              // ��� �����
                const string            font="Arial",             // �����
                const int               font_size=10,             // ������ ������
                const color             clr=clrRosyBrown,               // ����
                const double            angle=0.0,                // ������ ������
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LOWER,      // ������ ��������
                const bool              back=false,               // �� ������ �����
                const bool              selection=true,          // �������� ��� �����������
                const bool              hidden=false,              // ����� � ������ ��������
                const long              z_order=0)                // ��������� �� ������� �����
  {
   ResetLastError();
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": �� ������� ������� ������ \"�����\"! ��� ������ = ",GetLastError());
      return(false);
     }
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
color Color(bool P,color a,color b)
  {
   if(P) return(a);
   else return(b);
  }
//------------------------------------------------------------------
