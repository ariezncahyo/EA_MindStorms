// MoGri_Channel.mq4

// 10.08.2013 8:30

#property copyright ""



extern int		������_�������_������ = 5;	// ���������� �� ���� �� ���� ��������� �������. � ������
extern int		���_����� = 5;							// ���������� ����� �������� ������ �����������. � ������
extern int		�������_�����_������� = 3;	// ���-�� ������� � ���� �������
extern int		�����_����� = 10;						// ���� ���-�� ������������ ��������� �����
							
extern int		���������_����� = 15;	// ����� ���� �������/������ ���� ������� ����
extern int		���_����� = 5;				// ����� �� ������������ ����� ���� �������, ����������� ��� ������������ ����
							
extern double	���_������������� = 0.01;		// ���� = 0, ��� ����� ������������ (���_�_���������_����)
extern double	���_�_���������_���� = 0.01;		// ������������ ������ ���� ���_������������� = 0
							
extern bool		��������_���������� = false;	// ECN, NDD ���
extern bool		������ = true;								// �������� ��������� � ������?
extern bool		���� = true;									// �������� ���������� � ����?
extern int		��������������� = 2;					// ������




string
	gs_Symbol,
	gs_Prefix = "mgc_" // ������� ���
;
double
	gd_First_Level, gd_Level_Step,
	gd_Lot_Min, gd_Lot_Max, gd_Lot_Step, gd_Lot_Margin,
	gd_Stop_Level, gd_Freeze_Level,
	gd_Trail_Distance, gd_Trail_Step,
	gd_One_Pip_Rate
;
int
	gi_Trail_Distance, gi_Trail_Step,
	gi_Slippage, // ���������������
	gi_Orders_Limit = 0, // ����� �������� �������
	gi_Connect_Wait = 2, // ����� ����� �������� �������� ������. � ��������
	gi_Try_To_Trade = 4 // ���-�� ������� �������� ������
;
bool
	gb_Orders_Limit = false, // ���� ������ �������
	gb_Can_Trade = true // �������� ���������
;


void init() {
	gs_Symbol = Symbol();
	if(MathAbs(������_�������_������) <= MarketInfo(gs_Symbol, MODE_STOPLEVEL)) {
		Alert(gs_Symbol, ": ������_�������_������ ������ ���� ������ ", MarketInfo(gs_Symbol, MODE_STOPLEVEL), " ��!");
		return;
	}
	
	gd_One_Pip_Rate = MathPow(10, Digits);
	int i_Five_Digits_Ratio = 1;
	if(gd_One_Pip_Rate == 1000 || gd_One_Pip_Rate == 100000) i_Five_Digits_Ratio = 10;
	gd_First_Level = i_Five_Digits_Ratio * ������_�������_������ / gd_One_Pip_Rate;
	gd_Level_Step = i_Five_Digits_Ratio * ���_����� / gd_One_Pip_Rate;
	gi_Trail_Distance = i_Five_Digits_Ratio * ���������_�����;
	gi_Trail_Step = i_Five_Digits_Ratio * ���_�����;
//	gd_Trail_Distance = i_Five_Digits_Ratio * ���������_����� / gd_One_Pip_Rate;
//	gd_Trail_Step = i_Five_Digits_Ratio * ���_����� / gd_One_Pip_Rate;
	gi_Slippage = i_Five_Digits_Ratio * ���������������;
	gd_Freeze_Level = MarketInfo(gs_Symbol, MODE_FREEZELEVEL) / gd_One_Pip_Rate;
	gd_Stop_Level = MarketInfo(gs_Symbol, MODE_STOPLEVEL) / gd_One_Pip_Rate;
	
	gd_Lot_Min = MarketInfo(gs_Symbol, MODE_MINLOT);
	gd_Lot_Max = MarketInfo(gs_Symbol, MODE_MAXLOT);
	gd_Lot_Step = MarketInfo(gs_Symbol, MODE_LOTSTEP);
	gd_Lot_Margin = MarketInfo(gs_Symbol, MODE_MARGINREQUIRED);
	
	gi_Connect_Wait *= 1000;
}


int deinit() {return (0);}


int start() {
	if (!IsTesting() && IsStopped()) return (0);
	int
		i_Signal = 0, // ������ �����������
		ia_Magics[], // ������ �������� �����
		i_Magics, // ���-�� ��������� �����
		i_Magic, // ������ ���������� ����
		i_Level, // ���� ����
		i_Orders = OrdersTotal(), // ����� ���-�� �������� � ���������� �������
		i_Value, // ��������������� ����������
		i_Order // �����
	;
	double
		d_Sell_Max, d_Buy_Min,
		d_Sell_TP, d_Buy_TP,
		d_SL, d_TP, d_Level,
		d_Channel_Mid = 0, // ���� �������� ������
		d_Lot, // ������ ����
		da_Orders_Data[50] // ���������� �� ������������ �������
	;
	string
		s_Value // ��������������� ����������
	;
	static int
		sia_Grid_Trail[20][5], // ������ ���� ������� ������ ����
								// [][0] ������
								// [][1] ������ � �� �������� �������
								// [][2] ���� ��������� ��� ���� ����
								// [][3] ������ � �� �������� �������
								// [][4] ���-�� �������� �������
		si_Last_Signal_Time = 0
	;
	bool
		b_OK
	;
	
	i_Magics = Get_Magics_List(ia_Magics, gs_Symbol); // ��������� ������ �������� �����
	
	// ������������ ����� ����:
	if(i_Magics < �����_����� && si_Last_Signal_Time < Time[0]) i_Signal = Get_Signal(d_Channel_Mid); // ��������� �������
	if(i_Signal != 0) {
		s_Value = " �� ��� ������"; if(i_Signal < 0) s_Value = " �� ��� ������";
		s_Value = DoubleToStr(MathAbs((d_Channel_Mid - Bid) * gd_One_Pip_Rate), 0) + s_Value;
		i_Magic = Get_Magic(); // ���������� ������� ��� ���� ����
		if(������) Print("������������ ���� " + i_Magic + " � " + s_Value);
		if(gi_Orders_Limit > 0 && gi_Orders_Limit - 2 * �������_�����_������� < i_Orders) {
			// ���������� ����� ���� ������ ��-�� ������ �������
			if(������) Print("������������ ���������� ��-�� ������. ���� ", i_Orders, ", ����� ", (2 * �������_�����_�������), ", ����� ", gi_Orders_Limit);
		} else {
			d_Lot = Get_Lot(0, 0, ���_�_���������_����, ���_�������������); // ������ ����
			if(d_Lot > 0.0) { // ������� ����������
				i_Level = 0;
				// ����� ���� SellLimit + BuyLimit
				while(i_Level < �������_�����_�������) {
					i_Order = Send_Order(gs_Symbol,
						i_Magic,
						��������_����������, gi_Try_To_Trade, gi_Connect_Wait,
						OP_SELLLIMIT,
						d_Lot,
						Bid + gd_First_Level + i_Level * gd_Level_Step,
						gi_Slippage,
						DoubleToStr(Bid, Digits),
						0,
//						Bid + gd_First_Level + (i_Level - 1) * gd_Level_Step
						Bid
					);
					if(i_Order > 0) {
						gb_Orders_Limit = false; // ����� ���� ������
					} else if(i_Order == -148) {
						if(������) Print("������������ �������� - ��������� ������ ���-�� �������");
						gi_Orders_Limit = i_Orders + 2 * i_Level + 1; // ����� ������
						gb_Orders_Limit = true; // ���� ������
						break; // �������� ������������
					}
					i_Order = Send_Order(gs_Symbol,
						i_Magic,
						��������_����������, gi_Try_To_Trade, gi_Connect_Wait,
						OP_BUYLIMIT,
						d_Lot,
						Bid - gd_First_Level - i_Level * gd_Level_Step,
						gi_Slippage,
						DoubleToStr(Bid, Digits),
						0,
//						Bid - gd_First_Level - (i_Level - 1) * gd_Level_Step
						Bid
					);
					if(i_Order > 0) {
						gb_Orders_Limit = false; // ����� ���� ������
					} else if(i_Order == -148) {
						if(������) Print("������������ �������� - ��������� ������ ���-�� �������");
						gi_Orders_Limit = i_Orders + 2 * i_Level + 2; // ����� ������
						gb_Orders_Limit = true; // ���� ������
						break; // �������� ������������
					}
					i_Level++;
				}
				si_Last_Signal_Time = Time[0]; // ��������� ����� ���� ���������� �������
			} else if(������) Print("������ ������������ - ��� ����� ��� �������� ������ �������� �����");
		}
	}
	
	// ������������� �����:
	// ������������ ������ �����:
	if(i_Magics > 0) {
		int i_Tmp_Array[20][3];
		i_Magic = i_Magics;
		while(i_Magic > 0) {
			i_Magic--;
			
			i_Tmp_Array[i_Magic][0] = ia_Magics[i_Magic]; // ������
			i_Tmp_Array[i_Magic][1] = -1000000; // ���� �������
			
			i_Level = 20;
			while(i_Level > 0) {
				i_Level--;
				
				if(i_Tmp_Array[i_Magic][0] == sia_Grid_Trail[i_Level][0]) {
					i_Tmp_Array[i_Magic][1] = sia_Grid_Trail[i_Level][1];
					i_Tmp_Array[i_Magic][2] = sia_Grid_Trail[i_Level][2];
					break; //i_Level = -100;
				}
			}
		}
		i_Magic = i_Magics;
		ArrayInitialize(sia_Grid_Trail, 0);
		while(i_Magic > 0) {
			i_Magic--;
			sia_Grid_Trail[i_Magic][0] = i_Tmp_Array[i_Magic][0];
			sia_Grid_Trail[i_Magic][1] = i_Tmp_Array[i_Magic][1];
			sia_Grid_Trail[i_Magic][2] = i_Tmp_Array[i_Magic][2];
			sia_Grid_Trail[i_Magic][3] = Get_Fixed_Pips(sia_Grid_Trail[i_Magic][0], gs_Symbol, i_Order);
			sia_Grid_Trail[i_Magic][4] = i_Order;
		}
	} else ArrayInitialize(sia_Grid_Trail, 0);
	
	i_Magic = i_Magics;
	while(i_Magic > 0) {
		i_Magic--;
		Get_Orders_Data(ia_Magics[i_Magic], da_Orders_Data, gs_Symbol); // ���� ���������� �� ������� ����
		i_Value = sia_Grid_Trail[i_Magic][3] + da_Orders_Data[24] + da_Orders_Data[25]; // ������� � ������
		if(����) Show_Info(da_Orders_Data, i_Magic, sia_Grid_Trail); // ����� ���� �� ����
		
		// ���� �������:
		if(i_Value > 0) { // ������� ����
			if(sia_Grid_Trail[i_Magic][1] < i_Value) // ������� �������
				sia_Grid_Trail[i_Magic][1] = i_Value; // ��������� ����� ����
			else { // ������� �� �������
				if(sia_Grid_Trail[i_Magic][1] > gi_Trail_Distance) { // ���� �������
					if(sia_Grid_Trail[i_Magic][1] - i_Value > gi_Trail_Step) { // �����, ���� ���������
						if(������) Print("������������ ���� ", ia_Magics[i_Magic], " � �������� " + i_Value + " ��");
						sia_Grid_Trail[i_Magic][2] = 3; // ����� ����: ���������� ����
						b_OK = true; // ���� ��������� �������� ����
						if(!KillEm(sia_Grid_Trail[i_Magic][0], -20)) // ������� ������� ����������
							b_OK = false; // �� �� ���������
						if(!KillEm(sia_Grid_Trail[i_Magic][0], -10)) // ������� ������� �������� �����������
							b_OK = false; // �� �� ���������
						
						if(b_OK) {
							sia_Grid_Trail[i_Magic][2] = 0; // ����� ����: �������� �������
							RemoveObjects(gs_Prefix);
						}
						
						continue; // � ��������� ����
					}
				}
			}
		}
		// ��������� ����:
		i_Orders = OrdersTotal(); // �������� ����� ���-�� �������� � ���������� �������
		if(sia_Grid_Trail[i_Magic][2] != 3) { // ���� ������������� ����
			if(da_Orders_Data[35] + da_Orders_Data[45] < 2 * �������_�����_�������) { // ����� ��������� ����
				if(Get_Outer_Prices(sia_Grid_Trail[i_Magic][0], gs_Symbol, d_Sell_Max, d_Sell_TP, d_Buy_Min, d_Buy_TP, d_Lot)) {
					if(da_Orders_Data[35] < �������_�����_�������) { // ���������� ������� BuyLimit
						if(gi_Orders_Limit > 0 && gi_Orders_Limit <= i_Orders) {
							if(������) Print("��������� ���������� ��-�� ������ (" + gi_Orders_Limit + ") �������");
						} else {
							d_Buy_Min -= gd_Level_Step;
							if(d_Buy_Min == -gd_Level_Step) d_Buy_Min = Bid - gd_Level_Step;
							while(d_Buy_Min > Ask - gd_Stop_Level) d_Buy_Min -= gd_Level_Step;
							if(d_Buy_TP < d_Buy_Min) {
								d_Buy_TP = d_Sell_TP;
								if(d_Buy_TP < d_Buy_Min) d_Buy_TP = d_Buy_Min + �������_�����_������� * gd_Level_Step;
							}
							if(������) Print("��������� ���� " + sia_Grid_Trail[i_Magic][0]);
							i_Order = Send_Order(gs_Symbol,
								sia_Grid_Trail[i_Magic][0],
								��������_����������, gi_Try_To_Trade, gi_Connect_Wait,
								OP_BUYLIMIT,
								d_Lot,
								d_Buy_Min,
								gi_Slippage,
								"", 0,
								d_Buy_TP
//								da_Orders_Data[22]
		//						da_Orders_Data[8] + gd_First_Level
		//						da_Orders_Data[36]
							);
							if(i_Order > 0) {
								i_Orders++;
								if(i_Orders < gi_Orders_Limit || gi_Orders_Limit < 1)
									gb_Orders_Limit = false; // ����� ���� ������
							} else if(i_Order == -148) {
								gi_Orders_Limit = i_Orders; // ��������� �����
								if(!gb_Orders_Limit) if(������) Print("��������� ������ (" + gi_Orders_Limit + ") ���-�� �������");
								gb_Orders_Limit = true; // ���� ������
							} else if(i_Order < 0) if(������) Print("������ ����������� BuyLimit ����� ", da_Orders_Data[39], " �� �������", da_Orders_Data[36] - gd_Level_Step, " SL=", da_Orders_Data[36], " Ask=", Ask);
						}
					}
					if(da_Orders_Data[45] < �������_�����_�������) { // ������� SellLimit ������ ���������
						if(gi_Orders_Limit > 0 && gi_Orders_Limit <= i_Orders) {
							if(������) Print("��������� ���������� ��-�� ������ (" + gi_Orders_Limit + ") �������");
						} else {
							d_Sell_Max += gd_Level_Step;
							if(d_Sell_Max == gd_Stop_Level) d_Sell_Max = Bid + gd_Level_Step;
							while(d_Sell_Max < Ask + gd_Stop_Level) d_Sell_Max += gd_Level_Step;
							if(d_Sell_TP == 0.0 || d_Sell_TP > d_Sell_Max) {
								d_Sell_TP = d_Buy_TP;
								if(d_Sell_TP == 0.0 || d_Sell_TP > d_Sell_Max) d_Sell_TP = d_Sell_Max - �������_�����_������� * gd_Level_Step;
							}
							if(������) Print("��������� ���� " + sia_Grid_Trail[i_Magic][0]);
							i_Order = Send_Order(gs_Symbol,
								sia_Grid_Trail[i_Magic][0],
								��������_����������, gi_Try_To_Trade, gi_Connect_Wait,
								OP_SELLLIMIT,
								d_Lot,
								d_Sell_Max,
								gi_Slippage,
								"", 0,
								d_Sell_TP
//								da_Orders_Data[23]
		//						da_Orders_Data[11] - gd_First_Level
		//						da_Orders_Data[47]
							);
							if(i_Order > 0) {
								i_Orders++;
								if(i_Orders < gi_Orders_Limit || gi_Orders_Limit < 1)
									gb_Orders_Limit = false; // ����� ���� ������
							} else if(i_Order == -148) {
								if(������) Print("��������� ������ ���-�� �������");
								gb_Orders_Limit = true; // ���� ������
								gi_Orders_Limit = da_Orders_Data[4] + da_Orders_Data[5] + da_Orders_Data[30] + da_Orders_Data[35] + da_Orders_Data[40] + da_Orders_Data[45]; // ��������� �����
							} else if(i_Order < 0) if(������) Print("������ ����������� SellLimit ����� ", da_Orders_Data[48], " �� ������� ", da_Orders_Data[47] + gd_Level_Step, " SL=", da_Orders_Data[47], " Bid=", Bid);
						}
					}
				}
			}
		}
		// ���������� ����:
		i_Orders = OrdersTotal(); // �������� ����� ���-�� �������� � ���������� �������
		if(sia_Grid_Trail[i_Magic][2] == 3) { // ���� ���������� ����
			if(������) Print("����� ���������� ���� " + sia_Grid_Trail[i_Magic][0] + ". ������� Buy=", DoubleToStr(da_Orders_Data[4], 0), " Sell=", DoubleToStr(da_Orders_Data[5], 0), " BuyLimit=", DoubleToStr(da_Orders_Data[35], 0), " SellLimit=", DoubleToStr(da_Orders_Data[45], 0));
			b_OK = true;
			if(da_Orders_Data[35] + da_Orders_Data[45] > 0) { // ���� ����������
				if(!KillEm(sia_Grid_Trail[i_Magic][0], -20)) // ������� ������� ����������
					b_OK = false; // �� �� ���������
			}
			if(da_Orders_Data[4] + da_Orders_Data[5] > 0) { // ���� ��������
				if(!KillEm(sia_Grid_Trail[i_Magic][0], -10)) // ������� ������� �������� �����������
					b_OK = false; // �� �� ���������
			}
			
			if(b_OK) sia_Grid_Trail[i_Magic][2] = 0; // ����� ����: �������� �������
		}
	}
	
	return(0);
}



int Error_Handle(int iError) {
	// �� ���� ������� by Nikolay Khrushchev N.A.Khrushchev@gmail.com
	switch(iError) {
		// ������ 1: �� ���������� �������
		case 2: if(������) Print("����� ������ (", iError, ")"); return(0);
		case 4: if(������) Print("�������� ������ ����� (", iError, ")"); return(0);
		case 8: if(������) Print("������� ������ ������� (", iError, ")"); return(0);
		case 129: if(������) Print("������������ ���� (", iError, ")"); return(0);
		case 135: if(������) Print("���� ���������� (", iError, ")"); return(0);
		case 136: if(������) Print("��� ��� (", iError, ")"); return(0);
		case 137: if(������) Print("������ ����� (", iError, ")"); return(0);
		case 138: if(������) Print("����� ���� (", iError, ")"); return(0);
		case 141: if(������) Print("������� ����� �������� (", iError, ")"); return(0);
		case 146: if(������) Print("���������� �������� ������ (", iError, ")"); return(0);
		// ������ 2: ���������� �������
		case 0: if(������) Print("������ ����������� (", iError, ")"); return(1);
		case 1: if(������) Print("��� ������, �� ��������� �� �������� (", iError, ")"); return(1);
		case 3: if(������) Print("������������ ��������� (", iError, ")"); return(1);
		case 6: if(������) Print("��� ����� � �������� �������� (", iError, ")"); return(1);
		case 128: if(������) Print("����� ���� �������� ���������� ������ (", iError, ")"); return(1);
		case 130: if(������) Print("������������ ����� (", iError, ")"); return(1);
		case 131: if(������) Print("������������ ����� (", iError, ")"); return(1);
		case 132: if(������) Print("����� ������ (", iError, ")"); return(1);
		case 133: if(������) Print("�������� ��������� (", iError, ")"); return(1);
		case 134: if(������) Print("������������ ����� ��� ���������� �������� (", iError, ")"); return(1);
		case 139: if(������) Print("����� ������������ � ��� �������������� (", iError, ")"); return(1);
		case 145: if(������) Print("����������� ���������, ��� ��� ����� ������� ������ � ����� (", iError, ")"); return(1);
		case 148: if(������) Print("���������� �������� � ���������� ������� �������� �������, �������������� �������� (", iError, ")"); return(3);
		// ������ 3: ��������� ������
		case 5: if(������) Print("������ ������ ����������� ��������� (", iError, ")"); return(2);
		case 7: if(������) Print("������������ ���� (", iError, ")"); return(2);
		case 9: if(������) Print("������������ �������� ���������� ���������������� ������� (", iError, ")"); return(2);
		case 64: if(������) Print("���� ������������ (", iError, ")"); return(2);
		case 65: if(������) Print("������������ ����� ����� (", iError, ")"); return(2);
		case 140: if(������) Print("��������� ������ ������� (", iError, ")"); return(2);
		case 147: if(������) Print("������������� ���� ��������� ������ ��������� �������� (", iError, ")"); return(2);
		case 149: if(������) Print("������� ������� ��������������� ������� � ��� ������������ � ������, ���� ������������ ��������� (", iError, ")"); return(2);
		case 150: if(������) Print("������� ������� ������� �� ����������� � ������������ � �������� FIFO (", iError, ")"); return(2);
	}
}                     


int Send_Order(string sSymbol, int iMagic, bool b_Market_Exec, int iAttempts, int iConnect_Wait, int iOrder_Type, double dLots, double dPrice, int iSlippage, string sComment="", double dSL=0, double dTP=0) {
	// �������� ������� �� ����������� ������
	// ���������� ����� ������ ��� -1
	// ���������� �������: Error_Handle()
	int
		iTry = iAttempts,
		i_Ticket = -1
	;
	
	while(iTry > 0) { // ������� ���������
		iTry--;
		if(IsTradeAllowed()) {
			if(b_Market_Exec) i_Ticket = OrderSend(sSymbol, iOrder_Type, dLots, NormalizeDouble(dPrice, Digits), iSlippage, 0, 0, sComment, iMagic);
			else i_Ticket = OrderSend(sSymbol, iOrder_Type, dLots, NormalizeDouble(dPrice, Digits), iSlippage, dSL, dTP, sComment, iMagic);
			
			if(b_Market_Exec && i_Ticket > 0 && (dSL > 0.0 || dTP > 0.0)) {
				if(OrderSelect(i_Ticket, SELECT_BY_TICKET))
					OrderModify(OrderTicket(), OrderOpenPrice(), dSL, dTP, 0);
			}
		} else {Sleep(1000 * iConnect_Wait); continue;}
		
		if(i_Ticket >= 0) break;
		switch(Error_Handle(GetLastError())) {
			case 0: RefreshRates(); Sleep(1000 * iConnect_Wait); break;
			case 1: return(i_Ticket);
//			case 2: gb_Can_Trade = false; return(i_Ticket);
			case 2: return(i_Ticket);
			case 3: return(-148);
		}
	}
	return(i_Ticket);
}


void Get_Orders_Data(int i_Magic, double& da_Orders_Data[], string s_Symbol) {
	// ���������� � ������ da_Orders_Data ��������� ���������� � �������� �������
		// [0] �������
		// [1] ������
		// [2] ���-�� ���������� �������
		// [3] ���-�� ��������� �������
		// [4] ���-�� ������� Buy
		// [5] ���-�� ������� Sell
		// [6] ����� ����� Buy
		// [7] ����� ����� Sell
		// [8] ���� �������� ����� Buy
		// [9] ���� ������� ����� Buy
		// [10] ���� �������� ����� Sell
		// [11] ���� ������� ����� Sell
		// [12] ��� ���������� �����: 0=Buy, 1=Sell, -1=���
		// [13] ��� ���������� �����
		// [14] ���� ���������� �����
		// [15] ����� ���������� �����
		// [17] ??
		// [18] ����� �������� ����� Buy
		// [19] ����� ������� ����� Buy
		// [20] ����� �������� ����� Sell
		// [21] ����� ������� ����� Sell
		// [22] ����� �� �������� �������� ����� Buy
		// [23] ����� �� �������� ������� ����� Sell
		// [24] ����� ������� Buy
		// [25] ����� ������� Sell
		// [26] ������� Buy
		// [27] ������� Sell
		// [28] ����� ������� StopLos Buy
		// [29] ����� ������� StopLos Sell
		
		// [30] ���-�� ���������� ������� BuyStop
		// [31] ���� ������� ������ BuyStop
		// [32] ���� �������� ������ BuyStop
		// [33] ��� �������� ������ BuyStop
		// [34] ��� ������� ������ BuyStop
		
		// [35] ���-�� ���������� ������� BuyLimit
		// [36] ���� ������� ������ BuyLimit
		// [37] ���� �������� ������ BuyLimit
		// [38] ��� �������� ������ BuyLimit
		// [39] ��� ������� ������ BuyLimit
		
		// [40] ���-�� ���������� ������� SellStop
		// [41] ���� ������� ������ SellStop
		// [42] ���� �������� ������ SellStop
		// [43] ��� �������� ������ SellStop
		// [44] ��� ������� ������ SellStop
		
		// [45] ���-�� ���������� ������� SellLimit
		// [46] ���� ������� ������ SellLimit
		// [47] ���� �������� ������ SellLimit
		// [48] ��� �������� ������ SellLimit
		// [49] ��� ������� ������ SellLimit
		
	// ���������� ����������: gd_One_Pip_Rate
	
	ArrayInitialize(da_Orders_Data, 0);
	da_Orders_Data[12] = -1;
	int
		iOrder = OrdersTotal(),
		i_Last_Entry_Time = 0
	;
	double
		d_Value
	;
	if(iOrder < 1) return;
	
	while(iOrder > 0) { // ������� �������
		iOrder--;
		if(OrderSelect(iOrder, SELECT_BY_POS, MODE_TRADES))
			if(OrderSymbol() == s_Symbol)
				if(OrderMagicNumber() == i_Magic || i_Magic == 0) { // ��� ������
					// �������/������
					d_Value = OrderProfit() + OrderSwap();
					if(d_Value > 0) {
						da_Orders_Data[0] += d_Value; // �������
						da_Orders_Data[2] += 1; // ���-�� ����������
					}
					else {
						da_Orders_Data[1] += d_Value; // ������
						da_Orders_Data[3] += 1; // ���-�� ���������
					}
					if(i_Last_Entry_Time < OrderOpenTime() && OrderType() < 2) {
						i_Last_Entry_Time = OrderOpenTime();
						da_Orders_Data[12] = OrderType(); // ����������� ���������� �����
						da_Orders_Data[13] = OrderLots(); // ��� ���������� �����
						da_Orders_Data[14] = OrderOpenPrice(); // ����������� ���������� �����
						da_Orders_Data[15] = OrderTicket(); // ����� ���������� �����
					}
					switch(OrderType()) {
						case OP_BUY:
								da_Orders_Data[4] += 1; // ������� �������� ������� �� �������
								da_Orders_Data[6] += OrderLots(); // ����� ����� ������� �� �������
								da_Orders_Data[24] += Bid - OrderOpenPrice(); // ������� � ������� ������� �� �������
								da_Orders_Data[26] += d_Value; // ������� ������� �� �������
								da_Orders_Data[28] += OrderOpenPrice() - OrderStopLoss(); // SL ������� �� �������
								if(OrderOpenPrice() > da_Orders_Data[8]) {
									da_Orders_Data[8] = OrderOpenPrice(); // ���� �������� ����� Buy
									da_Orders_Data[18] = OrderTicket(); // ����� �������� ����� Buy
									da_Orders_Data[22] = StrToDouble(OrderComment()); // ����� �� �������� �������� ����� Buy
								}
								if(OrderOpenPrice() < da_Orders_Data[9] || da_Orders_Data[9] == 0.0) {
									da_Orders_Data[9] = OrderOpenPrice(); // ���� ������� ����� Buy
									da_Orders_Data[19] = OrderTicket(); // ����� ������� ����� Buy
								}
								break;
						case OP_SELL:
								da_Orders_Data[5] += 1; // ������� �������� ������� �� �������
								da_Orders_Data[7] += OrderLots(); // ����� ����� ������� �� �������
								da_Orders_Data[25] += OrderOpenPrice() - Ask; // ������� � ������� ������� �� �������
								da_Orders_Data[27] += d_Value; // ������� ������� �� �������
								da_Orders_Data[29] += OrderStopLoss() - OrderOpenPrice(); // SL ������� �� �������
								if(OrderOpenPrice() > da_Orders_Data[10]) {
									da_Orders_Data[10] = OrderOpenPrice(); // ���� �������� ����� Sell
									da_Orders_Data[20] = OrderTicket(); // ����� �������� ����� Sell
								}
								if(OrderOpenPrice() < da_Orders_Data[11] || da_Orders_Data[11] == 0.0) {
									da_Orders_Data[11] = OrderOpenPrice(); // ���� ������� ����� Sell
									da_Orders_Data[21] = OrderTicket(); // ����� ������� ����� Sell
									da_Orders_Data[23] = StrToDouble(OrderComment()); // ����� �� �������� ������� ����� Sell
								}
								break;
						case OP_BUYLIMIT:
								da_Orders_Data[35] += 1; // ������� ���������� ������� BuyLimit
								if(OrderOpenPrice() > da_Orders_Data[37]) {
									da_Orders_Data[37] = OrderOpenPrice(); // ���� �������� ������ BuyLimit
									da_Orders_Data[38] = OrderLots(); // ��� �������� ������ BuyLimit
								}
								if(OrderOpenPrice() < da_Orders_Data[36] || da_Orders_Data[36] == 0.0) {
									da_Orders_Data[36] = OrderOpenPrice(); // ���� ������� ������ BuyLimit
									da_Orders_Data[39] = OrderLots(); // ��� ������� ������ BuyLimit
								}
								break;
						case OP_SELLLIMIT:
								da_Orders_Data[45] += 1; // ������� ���������� ������� SellLimit
								if(OrderOpenPrice() > da_Orders_Data[47]) {
									da_Orders_Data[47] = OrderOpenPrice(); // ���� �������� ������ SellLimit
									da_Orders_Data[48] = OrderLots(); // ��� �������� ������ SellLimit
								}
								if(OrderOpenPrice() < da_Orders_Data[46] || da_Orders_Data[46] == 0.0) {
									da_Orders_Data[46] = OrderOpenPrice(); // ���� ������� ������ SellLimit
									da_Orders_Data[49] = OrderLots(); // ��� ������� ������ SellLimit
								}
								break;
						case OP_BUYSTOP:
								da_Orders_Data[30] += 1; // ������� ���������� ������� BuyStop
								if(OrderOpenPrice() > da_Orders_Data[32]) {
									da_Orders_Data[32] = OrderOpenPrice(); // ���� �������� ������ BuyStop
									da_Orders_Data[33] = OrderLots(); // ��� �������� ������ BuyStop
								}
								if(OrderOpenPrice() < da_Orders_Data[31] || da_Orders_Data[31] == 0.0) {
									da_Orders_Data[31] = OrderOpenPrice(); // ���� ������� ������ BuyStop
									da_Orders_Data[34] = OrderLots(); // ��� ������� ������ BuyStop
								}
								break;
						case OP_SELLSTOP:
								da_Orders_Data[40] += 1; // ������� ���������� ������� SellStop
								if(OrderOpenPrice() > da_Orders_Data[42]) {
									da_Orders_Data[42] = OrderOpenPrice(); // ���� �������� ������ SellStop
									da_Orders_Data[43] = OrderLots(); // ��� �������� ������ SellStop
								}
								if(OrderOpenPrice() < da_Orders_Data[41] || da_Orders_Data[41] == 0.0) {
									da_Orders_Data[41] = OrderOpenPrice(); // ���� ������� ������ SellStop
									da_Orders_Data[44] = OrderLots(); // ��� ������� ������ SellStop
								}
								break;
					}
				}
	}
	
	da_Orders_Data[24] *= gd_One_Pip_Rate;
	da_Orders_Data[25] *= gd_One_Pip_Rate;
	da_Orders_Data[28] *= gd_One_Pip_Rate;
	da_Orders_Data[29] *= gd_One_Pip_Rate;
	return;
}



double Get_Lot(double dRisk_Percent, double dSL, double dLot_Rate=0, double dLot_Value=0) {
	// ������ ����
	// ���������� ����������: gd_Lot_Step, gd_Lot_Margin, gd_Lot_Min, gd_Lot_Max
	double dLot;
	
	if(dRisk_Percent > 0.0) // ��� ���� ������������ �� �������� ����� � SL
		dLot = gd_Lot_Step * MathFloor(dRisk_Percent * AccountFreeMargin() / 100 / dSL / MarketInfo(Symbol(), MODE_TICKVALUE) / gd_Lot_Step);
	else dLot = dLot_Value;
	if(dLot == 0)	dLot = gd_Lot_Step * MathFloor(dLot_Rate * AccountFreeMargin() / 100 / MarketInfo(Symbol(), MODE_TICKVALUE) / gd_Lot_Step);
	
	if(dLot < gd_Lot_Min) {
//		if(������) Print("���������: ��������� ��� (", dLot, ") ������ ����������� (", gd_Lot_Min, ")");
//		return(0);
		if(������) Print("��������� ��� (", dLot, ") �������� �� ����������� (", gd_Lot_Min, ")");
		dLot = gd_Lot_Min;
	}
	if(dLot > gd_Lot_Max) {
		if(������) Print("��������� ��� (", dLot, ") �������� �� ����������� (", gd_Lot_Max, ")");
		dLot = gd_Lot_Max;
	}
	
	return (dLot);
}


bool KillEm(int iMagic, int iOrder_Type = -1, int iClose_Type = 0, int iExclude_Ticket = -1) {
	// �������� � �������� �������, �������� ��������� � iExclude_Ticket �����
	// ���������� false, ���� �� ��� ������ ������� ������� ��� �������
	// ������������� �������� iOrder_Type ��������:
	// -1  : ������� ��
	// -10 : ������� ��� ��������
	// -20 : ������� ��� ����������
	// iClose_Type - ������������������ �������� �������:
	// 0 : �� ��������� � ������
	// 1 : ������ ����������
	// 2 : ������ ���������
	// 3 : ������� ���������
	// 4 : ������� ����������
	// 5 : ������� Buy
	// 6 : ������� Sell
	// 7 : �������� ���������
	// 8 : �� ������ � ���������
	// ���������� ����������: gs_Symbol, gi_Slippage, gi_Try_To_Trade, gi_Connect_Wait
	// ���������� �������: Error_Handle()
	int
		iTry,
		iNet_Orders = 0, // ���-�� �������� �������
		i_Ticket = -1,
		ia_Tickets_A[40], ia_Tickets_B[40], // 2 ������� ������� (buy/sell ��� ����������/���������)
		i_Tickets_A = -1, i_Tickets_B = -1, // ������� �������� �������
		iOrder = OrdersTotal() // ����� ���-�� �������� �������
	;
	bool
		b_OK = true // ��� ������ �������������
	;
	if(iOrder < 1) return(b_OK); // ��� �������
	double
		d_Price,
		dNet_Profit = 0 // ������
	;
	if(iClose_Type > 0) {ArrayInitialize(ia_Tickets_A, 0); ArrayInitialize(ia_Tickets_B, 0);}
	
	while(iOrder > 0) { // ������� �������
		iOrder--;
		if(OrderSelect(iOrder, SELECT_BY_POS, MODE_TRADES))
			if(OrderTicket() == iExclude_Ticket) continue;
			else if(OrderSymbol() == gs_Symbol)
				if(OrderMagicNumber() == iMagic) { // ��� ������
					i_Ticket = -1;
					iTry = gi_Try_To_Trade;
					if(OrderType() == OP_BUY && (iOrder_Type == OP_BUY || iOrder_Type == -1 || iOrder_Type == -10)) { // ��� ���� �������
						if(iClose_Type > 4) { // ���������� �� buy/sell
							i_Tickets_A++;
							ia_Tickets_A[i_Tickets_A] = OrderTicket(); // ������ ������ � ������ �������
						} else if(iClose_Type > 0) { // ���������� �� �������/�������
							if(OrderProfit() > 0.0) { // ������ ������ � ������ ����������
								i_Tickets_A++;
								ia_Tickets_A[i_Tickets_A] = OrderTicket();
							} else { // ������ ������ � ������ ���������
								i_Tickets_B++;
								ia_Tickets_B[i_Tickets_B] = OrderTicket();
							}
						} else // ������� ��������
							if(!Close_Order(OrderTicket(), gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
					} else if(OrderType() == OP_SELL && (iOrder_Type == OP_SELL || iOrder_Type == -1 || iOrder_Type == -10)) { // ��� ���� �������
						if(iClose_Type > 4) { // ���������� �� buy/sell
							i_Tickets_B++;
							ia_Tickets_B[i_Tickets_B] = OrderTicket(); // ������ ������ � ������ �������
						} else if(iClose_Type > 0) { // ���������� �� �������/�������
							if(OrderProfit() > 0.0) { // ������ ������ � ������ ����������
								i_Tickets_A++;
								ia_Tickets_A[i_Tickets_A] = OrderTicket();
							} else { // ������ ������ � ������ ���������
								i_Tickets_B++;
								ia_Tickets_B[i_Tickets_B] = OrderTicket();
							}
						} else // ������� ��������
							if(!Close_Order(OrderTicket(), gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
					} else // ��� ���� �������
						if(OrderType() > 1 && iOrder_Type == OrderType() || iOrder_Type == -1 || iOrder_Type == -20) {
							while(iTry > 0) { // ������� �������
								iTry--;
								if(IsTradeAllowed()) if(OrderDelete(OrderTicket())) i_Ticket = 1;
								else{Sleep(gi_Connect_Wait); continue;}
								if(i_Ticket >= 0) break;
								switch(Error_Handle(GetLastError())) {
									case 0: RefreshRates(); Sleep(gi_Connect_Wait); break;
									case 1: break;
									case 2: gb_Can_Trade = false; break;
								}
							}
							if(i_Ticket > -1) {
								iNet_Orders++; // ������� �������� �������
							} else {
								b_OK = false; // �� �� ���������
								if(������) Print("������ �������� ������ #", OrderTicket(), " OpenPrice=", OrderOpenPrice(), " Bid=", Bid, " Ask=", Ask);
							}
						}
				}
	}
	
	switch(iClose_Type) {
		case 0: // �� ��������� � ������
			return(b_OK);
		case 1:	// ������ ����������
			while(i_Tickets_A > -1) { // ����������
				if(!Close_Order(ia_Tickets_A[i_Tickets_A], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
				i_Tickets_A--;
			}
			return(b_OK);
		case 2:	// ������ ���������
			while(i_Tickets_B > -1) { // ���������
				if(!Close_Order(ia_Tickets_B[i_Tickets_B], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
				i_Tickets_B--;
			}
			return(b_OK);
		case 3:	// ������� ���������
			while(i_Tickets_B > -1) { // ���������
				if(!Close_Order(ia_Tickets_B[i_Tickets_B], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
				i_Tickets_B--;
			}
			while(i_Tickets_A > -1) { // ����������
				if(!Close_Order(ia_Tickets_A[i_Tickets_A], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
				i_Tickets_A--;
			}
			return(b_OK);
		case 4:	// ������� ����������
			while(i_Tickets_A > -1) { // ����������
				if(!Close_Order(ia_Tickets_A[i_Tickets_A], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
				i_Tickets_A--;
			}
			while(i_Tickets_B > -1) { // ���������
				if(!Close_Order(ia_Tickets_B[i_Tickets_B], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
				i_Tickets_B--;
			}
			return(b_OK);
		case 5:	// ������� buy
			while(i_Tickets_A > -1) { // buy
				if(!Close_Order(ia_Tickets_A[i_Tickets_A], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
				i_Tickets_A--;
			}
			while(i_Tickets_B > -1) { // sell
				if(!Close_Order(ia_Tickets_B[i_Tickets_B], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
				i_Tickets_B--;
			}
			return(b_OK);
		case 6:	// ������� sell
			while(i_Tickets_B > -1) { // sell
				if(!Close_Order(ia_Tickets_B[i_Tickets_B], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
				i_Tickets_B--;
			}
			while(i_Tickets_A > -1) { // buy
				if(!Close_Order(ia_Tickets_A[i_Tickets_A], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
				i_Tickets_A--;
			}
			return(b_OK);
		case 7:	// �������� ���������
			// ���� �������� ����������:
			while((i_Tickets_A + 1) * (i_Tickets_B + 1) > 0) {
				i_Ticket = MathMin(i_Tickets_A, i_Tickets_B);
				while(i_Ticket > -1) {
					if(!OrderCloseBy(ia_Tickets_B[i_Ticket], ia_Tickets_A[i_Ticket])) b_OK = false; // �� �� ���������
					i_Ticket--;
				}
				// ���������� ������� �������:
				i_Tickets_A = -1;
				i_Tickets_B = -1;
				ArrayInitialize(ia_Tickets_A, 0);
				ArrayInitialize(ia_Tickets_B, 0);
				
				iOrder = OrdersTotal();
				while(iOrder > 0) { // ������� �������
					iOrder--;
					if(OrderSelect(iOrder, SELECT_BY_POS, MODE_TRADES))
						if(OrderTicket() == iExclude_Ticket) continue;
						else if(OrderSymbol() == gs_Symbol)
							if(OrderMagicNumber() == iMagic) { // ��� ������
								i_Ticket = -1;
								if(OrderType() == OP_BUY) { // ��� ���� �������
									i_Tickets_A++;
									ia_Tickets_A[i_Tickets_A] = OrderTicket(); // ������ ������ � ������ �������
								} else if(OrderType() == OP_SELL) { // ��� ���� �������
									i_Tickets_B++;
									ia_Tickets_B[i_Tickets_B] = OrderTicket(); // ������ ������ � ������ �������
								}
							}
				}
			}
			// �������� ��������:
			while(i_Tickets_B > -1) { // sell
				if(!Close_Order(ia_Tickets_B[i_Tickets_B], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
				i_Tickets_B--;
			}
			while(i_Tickets_A > -1) { // buy
				if(!Close_Order(ia_Tickets_A[i_Tickets_A], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // �� �� ���������
				i_Tickets_A--;
			}
			return(b_OK);
	}
	
	return(b_OK);
}



bool Close_Order(int i_Ticket, int i_Try_To_Trade, int i_Slippage, double d_Lot=0) {
	// �������� ������ ��� ��� ����� �� ��������� ������
	
	if(!OrderSelect(i_Ticket, SELECT_BY_TICKET)) return(true); // ����� ������ ��� ���, ������ ������
	
	double dPrice;
	bool b_Done = false;
	while(i_Try_To_Trade > 0) { // ������� �������
		i_Try_To_Trade--;
		dPrice = Bid; if(OrderType() == OP_SELL) dPrice = Ask;
		if(d_Lot == 0.0) d_Lot = OrderLots();
		if(IsTradeAllowed()) b_Done = OrderClose(OrderTicket(), d_Lot, dPrice, i_Slippage);
		else{Sleep(gi_Connect_Wait); continue;}
		if(b_Done) return(true);
		
		Print("������ �������� ������. Ticket=", OrderTicket(), " Lot=", d_Lot, " Price=", dPrice, " Slippage=", i_Slippage, " Ask=", Ask, " Bid=", Bid);
		switch(Error_Handle(GetLastError())) {
			case 0: RefreshRates(); Sleep(gi_Connect_Wait); break;
			case 1: break;
			case 2: gb_Can_Trade = false; break;
		}
	}
	
	return(false);
}


void Label_Handle(string sLabelName, string sLabelText = "", string sLabelFontName = "Arial", int iLabelFontSize = 10, color cLabelFontColor = Bisque, int iCorner = 0, int iXpos = 0, int iYpos = 0, int iAngle = 0, int iWindow = 0, bool bBackground=false) {
	// ����-������� � ����� �������
	if(ObjectFind(sLabelName) != -1) ObjectDelete(sLabelName);
	if(sLabelText != "") {
		ObjectCreate(sLabelName, OBJ_LABEL, iWindow, 0, 0);
		ObjectSet(sLabelName, OBJPROP_CORNER, iCorner);
		ObjectSet(sLabelName, OBJPROP_XDISTANCE, iXpos);
		ObjectSet(sLabelName, OBJPROP_YDISTANCE, iYpos);
		ObjectSet(sLabelName, OBJPROP_ANGLE, iAngle);
		ObjectSet(sLabelName, OBJPROP_BACK, bBackground);
		ObjectSetText(sLabelName, sLabelText, iLabelFontSize, sLabelFontName, cLabelFontColor);
	}
}


void Show_Info(double da_Orders_Data[], int i_Level, int ia_Grid_Trail[][]) {
	// ����� ���������� �� ������
	// ���������� ����������: gs_Prefix, gd_Loss_Rate, gb_Orders_Limit
	int
		i_Value = 0,
		iX_Pos = 10,
		iY_Pos = 5 + 25 * (i_Level + 1)
	;
	string s_String;
	color c_Color;
	
	s_String = ia_Grid_Trail[i_Level][3];
	if(ia_Grid_Trail[i_Level][3] > 0) s_String = "+" + s_String;
	s_String = " ����=" + ia_Grid_Trail[i_Level][4] + " " + s_String;
	i_Value = da_Orders_Data[24] + da_Orders_Data[25];
	s_String = i_Value + " Buy=" + DoubleToStr(da_Orders_Data[4], 0) + " Sell=" + DoubleToStr(da_Orders_Data[5], 0) + s_String;
	if(i_Value > 0) s_String = "+" + s_String;
	i_Value += ia_Grid_Trail[i_Level][3];
	c_Color = Silver;
	if(i_Value < 0) c_Color = HotPink;
	else if(i_Value > 0) c_Color = LightGreen;
	Label_Handle(gs_Prefix + " ���� " + i_Level, s_String + " : " + ia_Grid_Trail[i_Level][0], "Arial", 10, c_Color, 3, iX_Pos, iY_Pos);
	// ����� �������:
	if(i_Level == 0) {
		iY_Pos = 5;
		if(gb_Orders_Limit) c_Color = OrangeRed;
		else c_Color = Silver;
		Label_Handle(gs_Prefix + " �������", "�������: " + OrdersTotal(), "Arial", 10, c_Color, 3, iX_Pos, iY_Pos);
	}
}


int Get_Signal(double& d_Channel_Mid) {
	// ��������� ������� ����� �� FX_SHIChannel � ����������� � �����������
	// � ���������� d_Channel_Mid ���������� ������� �������� ������
	d_Channel_Mid = iCustom(NULL, 0, "FX_SHIChannel", 1, 0); // ������� ����� �� ���� ����
	double d_Mid_Line_Prev = iCustom(NULL, 0, "FX_SHIChannel", 1, 1); // ������� ����� �� ����������
	
	if(d_Channel_Mid == Close[0]) return(0); // ���� �� �����, ��� �����������
	if(d_Mid_Line_Prev ==  Close[1]) { // ���������� ��� �������� �� �����
		d_Mid_Line_Prev = iCustom(NULL, 0, "FX_SHIChannel", 1, 2); // � ����� ���?
		if(d_Mid_Line_Prev ==  Close[2]) { // ����
			d_Mid_Line_Prev = iCustom(NULL, 0, "FX_SHIChannel", 1, 3); // � ����� ���?
			if(d_Mid_Line_Prev ==  Close[3]) // ���� ����������� ���� ��������� �� �����
				return(0); // ���
		}
	}
	
	if(Close[0] > d_Channel_Mid) {
		if(Close[1] < d_Mid_Line_Prev) return(1); // ����������� �����
	}
	else if(Close[1] > d_Mid_Line_Prev) return(-1); // ����������� ����
	
	return(0);
}


int Get_Magics_List(int& ia_Magics[], string s_Symbol) {
	// ��������� ������ ��������������� �����
	ArrayResize(ia_Magics, 0);
	int
		i_Order = OrdersTotal(),
		i_Magics = 0
	;
	if(i_Order < 1) return(i_Magics);
	
	while(i_Order > 0) { // ������� �������
		i_Order--;
		if(OrderSelect(i_Order, SELECT_BY_POS, MODE_TRADES))
			if(OrderSymbol() == s_Symbol)
				i_Magics = Array_Int_Push(ia_Magics, OrderMagicNumber(), i_Magics);
	}
	return(i_Magics);
}


int Get_Fixed_Pips(int i_Magic, string s_Symbol, int& i_Count) {
	// ������� � ������� �������� ������ ����� ������� �� ��������� �������. � ������
	// � ���������� i_Count �������� ���-�� �������� �������
	// ���������� ����������: gd_One_Pip_Rate
	
	i_Count = 0;
	int i_Order = OrdersHistoryTotal();
	if(i_Order < 1) return(0);
	
	double d_Pips = 0;
	
	while(i_Order > 0) { // ������� �������
		i_Order--;
		if(OrderSelect(i_Order, SELECT_BY_POS, MODE_HISTORY))
			if(OrderSymbol() == s_Symbol)
				if(OrderMagicNumber() == i_Magic) {
					if(OrderType() == OP_BUY) {i_Count++; d_Pips += OrderClosePrice() - OrderOpenPrice();}
					else if(OrderType() == OP_SELL) {i_Count++; d_Pips += OrderOpenPrice() - OrderClosePrice();}
				}
	}
	
	return(d_Pips * gd_One_Pip_Rate);
	
}


int Array_Int_Push(int& ia_Array[], int i_Value, int i_Count) {
	if(i_Count < 1) {
		ArrayResize(ia_Array, 1);
		ia_Array[0] = i_Value;
		i_Count = 1;
	} else {
		int i_Index = 0;
		while(i_Index < i_Count) {
			if(ia_Array[i_Index] == i_Value) break;
			i_Index++;
		}
		if(i_Index == i_Count) {
			ArrayResize(ia_Array, i_Count + 1);
			ia_Array[i_Index] = i_Value;
			i_Count++;
		}
	}
	
	return(i_Count);
}


int Get_Magic() {
	// ���������� ������ = 1 + ���� ���� (3 ��) + ������� ��� (5 ��)
	int i_Value = DayOfYear();
	string s_Value = "1";
	
	if(i_Value < 10) s_Value = "100" + i_Value;
	else if(i_Value < 100) s_Value = "10" + i_Value;
	else s_Value = "1" + i_Value;
	
	i_Value = TimeCurrent() - iTime(Symbol(), PERIOD_D1, 0);
	if(i_Value < 10) s_Value = s_Value + "0000" + i_Value;
	else if(i_Value < 100) s_Value = s_Value + "000" + i_Value;
	else if(i_Value < 1000) s_Value = s_Value + "00" + i_Value;
	else if(i_Value < 10000) s_Value = s_Value + "0" + i_Value;
	else s_Value = s_Value + i_Value;
	
	return(StrToInteger(s_Value));
}


int RemoveObjects(string sName="", bool bExact=false) {
	int iObjectID = ObjectsTotal();
	while(iObjectID > 0) {
		iObjectID--;
		if(sName == "") ObjectDelete(ObjectName(iObjectID)); // ���� ��� �� ������� - ����� ����!
		else {
			if(bExact) { // ���� ������ ������� ������ ����, ��� ��� �������
				if(ObjectName(iObjectID) == sName) ObjectDelete(ObjectName(iObjectID)); // kill'em
			}
			else {
				if(StringFind(ObjectName(iObjectID), sName) != 0) continue; // ���� ��� ����.������� �� ���������� � ���������� - �� ��� ������
				ObjectDelete(ObjectName(iObjectID)); // kill'em
			}
		}
	}
	
	return(0);
}


bool Get_Outer_Prices(int i_Magic, string s_Symbol, double& d_Sell_Max, double& d_Sell_TP, double& d_Buy_Min, double& d_Buy_TP, double& d_Lot) {
	// ����� ������� ������� (�������� � ��������) �� ��������� �������
	// ������� ������� ������ Buy ��� BuyLimit �������� � ���������� d_Buy_Min
	// � �������� Buy Sell ��� SellLimit - � d_Sell_Max
	
	int
		i_Order = OrdersTotal()
	;
	d_Sell_Max = 0;
	d_Buy_Min = 1000000;
	d_Lot = 0;
	d_Sell_TP = 0; d_Buy_TP = 0;
	
	// ������� �������� � ���������� �������:
	while(i_Order > 0) {
		i_Order--;
		if(OrderSelect(i_Order, SELECT_BY_POS, MODE_TRADES))
			if(OrderSymbol() == s_Symbol)
				if(OrderMagicNumber() == i_Magic) {
					if(OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT) {
						d_Lot = OrderLots();
						if(OrderOpenPrice() > d_Sell_Max) {
							d_Sell_Max = OrderOpenPrice();
							d_Sell_TP = OrderTakeProfit();
						}
					} else if(OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT) {
						d_Lot = OrderLots();
						if(OrderOpenPrice() < d_Buy_Min) {
							d_Buy_Min = OrderOpenPrice();
							d_Buy_TP = OrderTakeProfit();
						}
					}
				}
	}
	
	// ������� �������� �������:
	i_Order = OrdersHistoryTotal();
	while(i_Order > 0) {
		i_Order--;
		if(OrderSelect(i_Order, SELECT_BY_POS, MODE_HISTORY))
			if(OrderSymbol() == s_Symbol)
				if(OrderMagicNumber() == i_Magic) {
					if(OrderType() == OP_BUY) {
						d_Lot = OrderLots();
						if(OrderOpenPrice() < d_Buy_Min) {
							d_Buy_Min = OrderOpenPrice();
							d_Buy_TP = OrderTakeProfit();
						}
					} else if(OrderType() == OP_SELL) {
						d_Lot = OrderLots();
						if(OrderOpenPrice() > d_Sell_Max) {
							d_Sell_Max = OrderOpenPrice();
							d_Sell_TP = OrderTakeProfit();
						}
					}
				}
	}
	
	if(d_Lot > 0.0) return(true);
	return(false); // ������ �� �������
}