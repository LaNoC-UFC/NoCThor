#ifndef IN_MOD
#define IN_MOD

#include "SC_common.h"

SC_MODULE(inputmodule)
{
	sc_in<sc_logic> clock;
	sc_in<sc_logic> reset;
	
	sc_in<sc_logic> incredit[NUM_EP];
	sc_out<sc_logic> outtx[NUM_EP];
	sc_out<sc_lv<TAM_FLIT> > outdata[NUM_EP];
	
	void inline outTx(int Indice, int Booleano)
	{
		outtx[Indice]=((Booleano != 0)? SC_LOGIC_1: SC_LOGIC_0);
	}

	void inline outData(int Indice, unsigned long int Valor)
	{
		outdata[Indice] = Valor;
	}
	
	int inline inCredit(int Indice)
	{
		return (incredit[Indice] == SC_LOGIC_1)?1:0;
	}

	unsigned long int inline address(int index)
	{
		unsigned long int x, y, addr;
		x = index/NUM_ROT_X;
		y = index%NUM_ROT_Y;
		addr = (x << (TAM_FLIT/2)) + y;
		return addr;
	}

	unsigned long int CurrentTime;

	void Timer();
	void TrafficGenerator();
	
	SC_CTOR(inputmodule):
	reset("reset"),
 	clock("clock")
	{
		CurrentTime = 0;

		SC_CTHREAD(TrafficGenerator, clock.pos());  //uma CTHREAD, comeca a executar na primeira subida de clock e. (por tal razao tem um loop infinito dentro dela)
		//watching(reset.delayed() == true); //caso o sinal do reset seja 1, ele volta pro comeco da CTHREAD.

		SC_METHOD(Timer); // pro timer
		sensitive_pos << clock;
		dont_initialize();
	}
};

void inputmodule::Timer()
{
	++CurrentTime; //variavel que conta no numero de clocks, eh resetada no reset.
}

void inline inputmodule::TrafficGenerator()
{
	enum Estado{S1, S2, S3, S4, FimArquivo};
	CurrentTime = 0;
	FILE* Input[NUM_EP];
	char temp[100], TimestampNet[TAM_FLIT/4+1];
	unsigned long int Target[NUM_EP],Size[NUM_EP];
	unsigned long int* Packet[NUM_EP];
	Estado EstadoAtual[NUM_EP];
	int FlitNumber[NUM_EP], NumberofFlits[NUM_EP], WaitTime[NUM_EP];
	int Index,i,j,k;
	unsigned long int ended = 0, sent = 0;

	for(Index=0;Index<NUM_EP;Index++){
		sprintf(temp,"In/in%0*X.txt",TAM_FLIT/4,address(NUM_EP -1 -Index));
		Input[Index] = fopen(temp,"r");
		if(Input[Index] == NULL) {
			cout << "Couldnt open " << temp << endl;
			ended++;
		}

		outTx(Index,0);
		outData(Index,0);
		EstadoAtual[Index] = S1;
		FlitNumber[Index] = 0;
	}

	while(true){
		for(Index=0;Index<NUM_EP;Index++)
		{
			if(Input[Index] != NULL /*&& !feof(Input[Index])*/ && reset!=SC_LOGIC_1)
			{
				/*if(EstadoAtual[Index] == S4 && FlitNumber[Index]>=NumberofFlits[Index]) //garante a consistência da carga oferecida (permite nenhum ciclo entre pacotes
				{
					EstadoAtual[Index] = S1;
					free(Packet[Index]);
				}*/
				if(EstadoAtual[Index] == S1) //captura o tempo para entrada na rede
				{
						outTx(Index,0);
						outData(Index,0);
						FlitNumber[Index] = 0;
						fscanf(Input[Index],"%X",&WaitTime[Index]);
						EstadoAtual[Index] = S2;
						if(feof(Input[Index]))
						{
							fclose(Input[Index]);
							Input[Index] = NULL;
							ended++;
							sprintf(temp,"In/in%0*X.txt",TAM_FLIT/4,address(NUM_EP -1 -Index));
							cout << "Endend " << temp << " => " << ended << endl;
							outTx(Index,0);
							outData(Index,0);
							EstadoAtual[Index] = FimArquivo;
						}
				}			
				
				if(EstadoAtual[Index] == S2)//espera até o tempo para entrar na rede
				{
					outTx(Index,0);
					EstadoAtual[Index] = (CurrentTime >= WaitTime[Index]) ? S3 : S2;
				}
				
				if(EstadoAtual[Index] == S3)//prepara o pacote
				{
					//Captura o target
					fscanf(Input[Index],"%X",&Target[Index]);
					FlitNumber[Index]++;

					//Captura o size
					fscanf(Input[Index],"%X",&Size[Index]);
					Size[Index] += 4; //4 = Inserção do timestamp de entrada na rede
					NumberofFlits[Index] = Size[Index] + 2; //2 = header + size
					Packet[Index]=(unsigned long int*)calloc( sizeof(unsigned long int) , NumberofFlits[Index]);
					Packet[Index][0] = Target[Index];
					Packet[Index][1] = Size[Index];
					FlitNumber[Index]++;

					while(FlitNumber[Index] < 9 )//lendo os flits até o número de sequencia
					{
						fscanf(Input[Index], "%X", &Packet[Index][FlitNumber[Index] ]);
						FlitNumber[Index]++;
					}

					FlitNumber[Index]+=4; //eh o espaco que depois vai ter o TS de entrada na rede =)

					//Captura o payload
					while(FlitNumber[Index] < NumberofFlits[Index])
					{
						fscanf(Input[Index], "%X", &Packet[Index][FlitNumber[Index] ]);
						FlitNumber[Index]++;
					}
					EstadoAtual[Index] = S4;
					FlitNumber[Index] = 0;
				}
				
				if(EstadoAtual[Index]==S4 && inCredit(Index)==1) //comeca a transmitir os dados
				{
					if(FlitNumber[Index]>=NumberofFlits[Index])
					{
						outTx(Index,0);
						outData(Index,0);
						EstadoAtual[Index] = S1;
						free(Packet[Index]);
						//if(FlitNumber[Index]==NumberofFlits[Index])
						//	sent++;
					}
					else
					{
						if(FlitNumber[Index] == 0)
						{
							sent++;
							sprintf(temp, "%0*X",TAM_FLIT, CurrentTime);
							k = 9; //posição que deve ser inserido o timestamp de entrada na rede
							for(i=0,j=0;i<TAM_FLIT;i++,j++)
							{
								TimestampNet[j]=temp[i];
								if(j==TAM_FLIT/4-1)
								{
									sscanf(TimestampNet, "%X", &Packet[Index][k]);
									j=-1; //  porque na iteracao seguinte vai aumentar 1.
									k++;
								}
							}
						}

						outTx( Index , 1 );
						outData( Index , Packet[ Index ][ FlitNumber[ Index ] ] );
						FlitNumber[ Index ]++;
					}
				}
				
				if(EstadoAtual[Index] == FimArquivo)
				{
					outTx(Index,0);
					outData(Index,0);
				}
			}
		}
		if(ended >= NUM_EP) {
			FILE* npack = fopen("npack","w");
			fprintf(npack,"%ld",sent);
			fclose(npack);
			cout << sent << " packs sent." << endl;
			ended = 0;
		}
		wait();
	}
}

#endif// IN_MOD
