


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecOtp
                         █          ██████ █         █                █    █   █                    
            ██            █          █                              ██    █   █       █             
           █  █            ██                                       █                ███     ██   ██
           ████           █   █        █                       █           ██       ██  █    ██   ██
             █            ██  ██      ███                      █                      ███           
            █            ███  █       █   ██     ██            █                                    
            ██           ██  ██         █  █    █                       ██                          
           ██ █             ██          ███    █   █                                █  █            
              ██                              █     █                              █   █            
         ██    █                         ███  █  █ ██                           █████ ███           
          █ █   █                       █   █ █   █ █                          █ ██               █ 
█       █   █                           █      ███ █           ██              █                   █
      █                                 ██ █ ██                ██              ███      ██          
           █                ██           ███ ██                                        ███          
    ██     █   █            ██             █                                           █  █         
    █         █                          ██ ██                                         █  █         
   █      █ ███                          ██ █                                          █ █          
    ██    █   █       ██     ██          █  █                                                ████ █ 
    ███   █ ██       ██ █   █ ██          ██                                                 █   █  
 █      █   █       █  ███ ███  █                                                           ██   ██ 
  █      ██        ██    ███    ██                                                             █ █ █
 █                  ██    █    ██                                                             ███   
█                    █         █                          █                                      ██ 
                       █     █                             █                   █                  ██
                                   █  ███          ██    ███                  █ █                 ██
                         ███       █   ██          █ █                           █                  
                          █        █  ██            █ █                     ██   █                  
                          █           █              █                      ██████ ███              
                     ██                 █     ███                             █ ███   █    ███      
                    █  █               █                                   █      █   █    █  ██    
                     █ █                    █     █                      █   █    █   █     ███     
                      █                     █     █                     ███ ██     ███       █      
                                █           █     █                           █                     
                                █                                     ██       ██         ██        
         ███                    █             ███                     █       ██          ██        
                                                           ███        █                             
                                                                         █                          
                               ██           █                                                       
                              ██ █         █ █                                                  █   
                                            █ █                            ███                   █  
                                             ██                             ███ █   ██          █   
                              █     █ ██                     █         █  ███ ████  ██              
                               ███ ███                      █ █       ██ █ █ ██  █  ██              
                                  █      █                  █ █           █  █   █   ██             
                                   ██ ██ ██                  █                █ ██ ████  █          
     ██                               ███  █                                   █ ██   █  ███        
     ██                    █               ██                                     ██  ██   ██       
                         ██ █        ██    ██                                        █  █    ██ █ ██
                         ████      ██ ████ ██                                         █  █ █ █ █████
                               █    █ █    █                                              ██ ██████ 
    █                        ██ █    █  █  █                                      ███               
   ██                      ████  █      █                                         ███               
  ██                      █      █       █  ██                          ██     ██   █  █        ███ 
  ██                       ████████       ████                                 █      ██            
  █                         █    ██                                            █  █  █              
 █                              █                                     ██         █   █  █           
                                        █             ██       ███    ██              ███    █      
                                      ██  █          █  █     █   █           ██    █  █ ███  ██    
                                     █   ██          █  █    █   ██           █     ████  █  ██     
       █                ██       ███      █           ██         ██                 █     █         
      █ ██              █       ██       ██                 █      █         ██   █      █          
      █  █    ██         ██ █  █   █     ██                       ██         █ ███    █ █           
   █   █  █  ██           █ ████      █ ██                  ██      █       █  █  █                 
  ██  ███     █  █           ██                                ███ █            ██            ██    
 █   ██       █  █                                           ████ ██      ███   █         ██  █ █   
   █ ██       █  █             █                            █ ██           █ ██           ██   █    
     █        ██         ██    ██                          █                ███                     
 █  █                    ██                               ██                 █    ███               
  █                                       ███            █ █     █   ███                            
                                                        ███     ███  █ █                            
                                        █                █  █   ██    ██                            
                                        █                 █      █ █      ██                        
                                        █                 ███    █      ██ ██                       
       ██              █ █ ██ █   █                             █     ███ ███    ██                 
     ██  █           ██    ██ █   ███                            █         █     ██                 
     █  ███          █ █   █ ██  █  █                             ██  ██████          █             
     █    █          █           ███                                  ██  █         ██              
      █████          ██         ██                                      ██                          
        ██          █ █         █                                                  █       ██       
              ██    █  █             █                                                ██   ██       
              ██       █             █                         █                  █     █           
                    █                █                         ███              █ █    █            
                    █                                                          █ ██                 
                     █  ██                               █      ██                 █ █              
                      ███          ██                   ██     █               ██ █                 
       ██              █           ██                   █                       █                   
       ██                                               █ ██                     ██  █ ████         
                    █                                    ███   ██    ██            ██ ████          
  █               ██ ██                                      ██ █    ██              ███            
 ███              ██  █               ██                     ██ █             █      █ █            
██ ██            █    █          ██   ██                      █ █            █ █  ██           ███  
██   █            ████          █  █                       █    ██           ██   █  ██          █  
█ ██ █     █      ██             ██                        █    ██             █    ██       ██    █
 ████    █   █                                             █   █    █          █   ██        ███ ██ 
 █       █    █                                      ███    ███     █          ██  █          █  █  
         █    █                                      █      ███     █           █ █             █   
             █             █         █ █               █  █                     ███            ██  █
                          █  █ █    █                      █                    █               █ █ 
                         █ █   █    █      █         █  █ █         █          ██                   
                        ██ ██      █        █        █   █          ██        █ █                   
[EventDebug]: 102 event's created 
[QueueDebug]: 1 queue's created 
[ExecDebug]: 1 cache entries created 
[QueueResNil]: 301 
[QueueRes<T>]: 155 
	QueueResValDirect<array [,] of byte>: 1 
	QueueResValDirect<CLArray<byte>>: 51 
	QueueResValDirect<integer>: 102 
	QueueResValWrap<array [,] of byte>: 1 

#ReqModules
OpenCLABC


