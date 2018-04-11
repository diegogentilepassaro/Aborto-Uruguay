    * Dates of treatments
    global m_date_mvd     "2004m4"
    global m_date_florida "2008m8"
    global m_date_rivera  "2010m6"
    global m_date_salto   "2013m1"
    
    global q_date_mvd     "2004q2"
    global q_date_florida "2008q3"
    global q_date_rivera  "2010q3"
    global q_date_salto   "2013q1"
    
    global s_date_mvd     "2004h1"
    global s_date_florida "2008h2"
    global s_date_rivera  "2010h2"
    global s_date_salto   "2013h1"
    
    global y_date_mvd     2004 
    global y_date_florida 2008
    global y_date_rivera  2010 
    global y_date_salto   2013 

    * Ranges
    global m_pre  48
    global m_post 24
    global q_pre  16
    global q_post 12
    global s_pre  8
    global s_post 4
    global y_pre  4
    global y_post 2

    * Ranges SCM (to build synth control)
    global q_scm_pre  30
    global q_scm_post 16
    global s_scm_pre  20
    global s_scm_post 8
    global y_scm_pre  10
    global y_scm_post 4

    *Lag list (related to Ranges SCM)
    global q_lag_list " 8 9 10 11 12 13 14 15 16" //`" 1 3 5 7 "'
    global s_lag_list " 8 9 10 11 12 13 14 15 16 17 18 19 20 " //`" 5 6 7 8 9 10 11 12 "'
    global y_lag_list " 2 3 4 5 6 7 " //`" 3 4 5 6 "'

    * Legends
    global legend_mvd    = "Montevideo"
    global legend_rivera = "Rivera"
    global legend_salto  = "Salto"
    global legend_florida  = "Florida"
