**INTERNATIONAL BURCH UNIVERSITY**  
FACULTY OF ENGINEERING AND NATURAL SCIENCES  
DEPARTMENT OF INFORMATION TECHNOLOGIES

IBUgram Mobile Application for iOS

UNDERGRADUATE PROJECT  
Sead Smailagic

Mentor  
(mentor name, with academic title)

SARAJEVO  
June, 2023  
IBUgram Mobile Application for iOS

Sead Smailagic

Report Submitted in Fulfillment of Requirement for the  
Undergraduate Project

INTERNATIONAL BURCH UNIVERSITY  
2019/2020  
**APPROVAL PAGE**

**Student name and surname:**  Sead Smailagic  
**Faculty:**			   		  Faculty of Engineering and Natural Sciences  
**Department:** 			   	  Information Technologies  
**Project Title:** 		   		  IBUgram Mobile Application  
**Date of Defense:** 		   	  June 26th, 2020

I certify that this final work satisfies all the requirements as a Undergraduate Project for the Bachelor degree in Computer Science Engineering.

………………………………………  
      Assoc. Prof. Dr. Dino Kečo  
       **Head of Department**

This is to certify that I have read this final work and that in my opinion it is fully adequate, in scope and quality, as an Undergraduate Project for the Bachelor degree in Computer Science Engineering.

……………………………………  
										(mentor name, with academic title)  
					        	        		**Mentor**

**Examining Committee Members**

|  | Title / Name and Surname | Affiliation | Signature |
| ----- | :---: | :---: | :---: |
| 1\. | (fill in the committee names) | head |  |
| 2\. | ... | member |  |
| 3\. | ... | member |  |

It is approved that this final work has been written in compliance with the formatting rules laid down by the Department of Information Technologies.

………………………………………  
 						           			**Head of Committee**

**IBUgram Mobile Application for iOS**

# **ABSTRACT** {#abstract}

IBUgram is a comprehensive social networking platform tailored to the diverse community of International Burch University (IBU). This iOS application aims to foster a sense of university-wide connection by providing a dedicated space for students, faculty, and staff to share experiences, events, and moments within the IBU community. The overarching goal is to create a virtual environment that mirrors the vibrancy and inclusivity of campus life.

**Keywords:** Social Networking, SwiftUI, Mobile Application, University Community, Engagement, User Experience, Collaboration, Campus Life, IBU.

# **ACKNOWLEDGMENTS** {#acknowledgments}

Acknowledgements contain expressions of appreciation to the individuals or institutions who have helped the author in any way during his/her studies. A sample acknowledgement page is presented in the paragraphs below.

There are many people who helped to make my years at the graduate school most valuable. First, I thank ……, my major professor and dissertation supervisor. Having the opportunity to work with her over the years was intellectually rewarding and fulfilling. I also thank …… who contributed much to the development of this project starting from the early stages of my dissertation work. ……… provided valuable contributions to the development of the econometric model. I thank him for his insightful suggestions and expertise.

Many thanks to Department computer staff, who patiently answered my questions and problems on word processing. I would also like to thank to my undergraduate student colleagues who helped me all through the years full of class work and exams. My special thanks go to ……. whose friendship I deeply value.

The last words of thanks go to my family. I thank my parents …… and my brother ….. for their patience and encouragement. Lastly I thank my husband, …, for his endless support through this long journey

# **DECLARATION** {#declaration}

I hereby declare that this Undergraduate Project titled **IBUgram** is based on my original work except quotations and citations which have been duly acknowledged. I also declare that this work has not been previously or concurrently submitted for the award of any degree, at International Burch University, any other University or Institution.

………………………………  
				                   		        		Name Surname

            						        			June 26th, 2020  
					 		            

**TABLE OF CONTENTS**

**[ABSTRACT	2](#abstract)**

[**ACKNOWLEDGMENTS	3**](#acknowledgments)

[**DECLARATION	4**](#declaration)

[**1\. INTRODUCTION	1**](#introduction)

[1.1. Background	1](#background)

[1.2. Objective	1](#structure-of-the-paper)

[1.3. Significance of the Project	2](#structure-of-the-paper)

[1.4. Structure of the Paper	2](#structure-of-the-paper)

[**2\. SYSTEM ANALYSIS	4**](#system-analysis)

[**3\. APPLICATION DESIGN	5**](#application-design)

[**4\. IMPLEMENTATION	6**](#implementation)

[**5\. SYSTEM TESTING	7**](#system-testing)

[**6\. MAINTENANCE ANALYSIS	8**](#maintenance-analysis)

[**7\. CONCLUSION	9**](#conclusion)

**LIST OF TABLES**

[Table 1.1 A sample table	2](#table-1.1-a-sample-table)

**TABLE OF FIGURES**

[Figure 1.1 A sample figure	2](#figure-1.1-a-sample-figure)

**LIST OF ABBREVIATIONS**

**API**			Application Programming Interface

1. # **INTRODUCTION** {#introduction}

The landscape of modern education is evolving rapidly, and with it comes the need for innovative tools and platforms that can enhance the academic experience and foster a sense of community. In response to this demand, the iOS application "IBUgram" emerges as a pioneering endeavor tailored for the diverse members of International Burch University (IBU).

1. ## **Background** {#background}

International Burch University, a hub of diverse talents and cultures, requires a dynamic and inclusive platform to bring together its students, faculty, and staff. While existing social media platforms serve a general purpose, IBUgram is designed to cater specifically to the unique dynamics and interactions within the university community. It aims to transcend the limitations of traditional social networks, providing a space where the vibrancy of campus life can be celebrated and shared.

### 

2. ## **Objective** {#structure-of-the-paper}

The primary objective of IBUgram is to establish a digital ecosystem that mirrors the richness and inclusivity of university life. By leveraging the capabilities of SwiftUI, Apple's declarative framework for building user interfaces, the application seeks to provide an intuitive and visually engaging platform. Through features such as personalized profiles, multimedia sharing, and community-building tools, IBUgram aims to create an environment where members of the IBU community can connect, collaborate, and celebrate their shared experiences.

3. ## **Significance of the Project** {#structure-of-the-paper}

IBUgram addresses a critical gap in the social networking landscape specific to the university setting. The platform's significance lies in its ability to consolidate university-related content, events, and interactions in one centralized space. This not only fosters a sense of belonging among community members but also streamlines communication, making it easier for individuals to stay informed and engaged with campus life.

4. ## **Structure of the Paper** {#structure-of-the-paper}

Table numbers and captions should be centered above the table, using the same font as the rest of the document and a font size of 12 points.

*Table 1.1 A sample table*

| Column \#1 | Column \#2 |
| :---- | :---- |
| Value \#1 | Value \#2 |

**Figure Example**  
Figure numbers and captions should be centered below the illustration, using the same font as the rest of the document and a font size of 12 points.

![][image1]  
*Figure 1.1 A sample figure*

2. # **SYSTEM ANALYSIS** {#system-analysis}

This section should give a brief system overview, which includes the product’s perspective, scope, constraints and risks, and success criteria. Moreover, it should provide a quick glance into the primary system actors and key system features. Afterwards, it should present a feasibility and requirements analysis (functional and nonfunctional requirements) of the project. Not all of these sections are mandatory, but you should, at the very least, provide a functional and nonfunctional requirements analysis. [(Apple Inc, n.d.)](https://paperpile.com/c/q4F7o8/5l4R)

3. # **APPLICATION DESIGN** {#application-design}

This Chapter deals with functional, structural and behavioral modeling of the system through the use of diagrams. Here, you should include use case, activity, class, sequence and communication diagrams, as well as all other related diagrams (such as system and package diagrams). Moreover, you can include an ER (entity relationship) diagram of your database.

4. # **IMPLEMENTATION** {#implementation}

The following section should focus on the implementation part of the application: programming languages that are used in the application, hardware/software components and implementation environment definitions, APIs and services used, etc. Moreover, in this section you should describe how your application works and showcase it through several screenshots of your project.

5. # **SYSTEM TESTING** {#system-testing}

In this section, you should provide the results of testing conducted for your application, in the form of unit, integration and system tests. Additionally, you can include any other testing methods and frameworks that you used. Moreover, you can also discuss how testing results might impact further modifications of the project implementation.

6. # **MAINTENANCE ANALYSIS** {#maintenance-analysis}

The following section deals with system maintainability, data integrity and security concerns relating to the implementation of your project. You can discuss the administrative part  of the application, features and their maintenance, data maintenance and backup, restoring the data when application crashes, application security, future developments and data integrity, etc.

7. # **CONCLUSION** {#conclusion}

The “Conclusion” section should showcase the benefits of the project and the things you learned when implementing the project. Moreover, you can touch upon the future work that can improve this application. Apart from that, you should discuss the limitations faced when implementing the project and the general limitations that the application has. Lastly, you can provide use recommendations for better performance.  
**REFERENCES**

Surname, N. (2020). *Website Reference*. Retrieved 	June 20, 2020 from 	[https://w](https://blockgeeks.com/guides/best-bitcoin-script-guide/)ebsite.com

Surname, N. (2006). *Book Reference*. City, BA: Publisher

Surname, N., Surname, N., Surname, N. (2017). Journal Article Reference. *Journal 	Name*, pp. 145–154.  
**APPENDICES**

Some authors may desire to include certain material of the report in an appendix rather than in the main text. For example, an appendix may contain test forms, detailed apparatus descriptions, extensive tables of raw data, computer programs, etc.

[Apple Inc. (n.d.). *Swift*. Retrieved January 9, 2024, from](http://paperpile.com/b/q4F7o8/5l4R) [https://developer.apple.com/swift/](https://developer.apple.com/swift/)

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAckAAAEqCAYAAAB+76tdAAAkhElEQVR4Xu3dC3AV5f3/cUBRRlHHqVO17VhLtdpCy4zt1Avj1NKp1KqIyk9ofxjlZwsFFazAHy/8yk0h3AJiBEFEwkUsgkECco+RS7iaRLkG/hBIhHBPuBNIeP58t/+z2X0OCyfJ7p7dc96vmWc4u89zsuckh/2cZy/PU2/w4MG9L5TVFAqFQqFQbKV3PXmgAACAzYV8XEVIAgBwEYQkAAAOCEkAABwQkgAAOCAkAQBwQEgCAOCAkAQAwAEhCQCAA0ISAAAHhCQAAA4ISQAAHBCSAAA4CE1I7tmzRy1dulRt3LjRtr6wsFBlZWXZ1gEA4IZQhORPf/pTNXr0aLV161a1YMECc33jxo1VZmamKioqUg0bNlSVlZWWZwEAUDeBD8lz586pBx54QF9tBGLTpk3N5dzcXNW1a1dLi9hkZGRQKBRKqAu8E/iQLCgoUP369VNVVVXqxIkT5vrS0lKVkpJiLpeVlanWrVuby7EaOXJk1AeOQqFQwlTgncCH5IQJE1SjRo2MD8KkSZNUvXr1jPU5OTmqV69etrbNmze3Lcfik08+0VcBAGAIfEjOmDFDDR061Fx+8cUXVV5eniopKVHt2rUz1x86dEi1b9/eXI4VIQkAcBL4kMzPz1ddunQxlzt27KiKi4tVRUWFatKkibl+0aJFKjU11VyOFSEJAHAS+JAUcoh19uzZRqBFDrcKOQybnp5u3AJiXV8ThCQAwEkoQrJnz55GCEqZM2eOuT47O1vVr1/fWN+nTx/LM2JHSAIAnIQiJL1ESAIAnBCShCQAwAEhSUgCABwQkoQkAMABIUlIAgAcEJKEJADAASFJSAIAHBCShCQAwAEhSUgCABwQkoQkAMABIUlIAgAcEJKEJADAASFJSAIAHBCSNQzJ8+eV+teUfPXnfy1W5yrP69UAgARCSNYwJDfuLjMCUsq4Lwr1agBAAiEkaxiSoueEdWZQPjM4R68GACQIQrIWIXmg/LQZkhx2BYDERUjWIiTFpMXbbUEJAEg8hGQtQ1L8ZchXZki+PHY1PUoASDCEZB1Ccv32Q+rRvkvMoHx3zha9CQAgxAjJOoSkqLrQebQedt1z6KTeBAAQUoRkHUNS5O84zPlJAEhAhKQLISmsIbm0oFSvBgCEECHpUkiWnahQHYYtM4OyS/oqvQkAIGQISZdCMsLao1yUt0evBgCECCHpcki+mZFnhuSTA7PVrv0n9CYAgJAgJF0OSfF4v+rbQriQBwDCi5D0ICRFZKYQKW0u9CgBAOFDSHoUkkdPnrX1Jk9VVOpNAAABR0h6FJJi1srdtqCcu7ZEbxJIG3aVGQUAkh0h6WFIiv7TCsyQfGLAUr06cPaVVc9wUiXDCQFAEiMkPQ5J0br/UjN43v7kW706EM6eq1Lvzd1i6/m2HfSlOnK8Qm8KAEkjFCG5efNms+zcudNWV1hYqLKysmzrasKPkBTW8Nm256heHVcyQpD19ekFAJJVKEKyXr16ZrnyyivN9bm5ueb6Zs2aWZ4RO79C8n9GrjBDp+OFxydOn9ObxMWZs1VRofj6R1/bljnqCiBZhSIkH374YX2VQcIxokePHmrx4pr3evwKSTF3TUmgemhya4r19TzWb4kZiFmW1yqHXQEgGYUmJM+ft3dnSktLVUpKirlcVlamWrdubWkRm7S0NJWRkeFbeWbggurwGTA/qt6PkjZ+ui0cpYyfOCWqnbV++LjpUfUUCiUYBd4JRUheccUVqmHDhurOO+9Uu3fvNtYVFBSobt262dq1aNHCthwLP3uSYkfpMVv4+E1uS7FeSCRl5opdejPDyMxNZpuu763isCuApBOKkLSKHGLNz89XnTt3ttW1bNnSthwLv0NSDPl0gxk+j18IrM3F5XoTTzw7vHqWEilype3lzo1y2BVAMgttSFZUVKgmTZqY6xctWqRSU1PN5VjFIyRF0b7jvvUoe09cb9uWlJ0Xth+rR/tWj0W7cTeDDABIHoEPyaqqKtuy9WId6+O2bduqkpKaj2gTr5AU1tD697IivdoV67cfigrIEZ9t1Jtdkn7YFQCSReBDMi8vTzVo0MAIxGuvvVYdPHjQrMvOzlb169c36vr06WN5VuziGZL67RflJ87qTWptf9lp9er4tbaf/+KY2v+ZrT+HAQYAJIvAh6TX4hmSYnH+XlsAfZxjHyyhpmTknDFzt9p+5n8N+lKt2LRfb1ojm3aXcdgVQNIhJOMckmLk7OrDmXKvYl1Ib9EakFKkV+kG62HXuvRKASAsCMkAhKR46q3qG/tlxJua0g/dSvnLkK/0ZnVm/fllJzjsCiCxEZIBCcnsb+zjp9aEXKnaaXSu7flyRevhY+6HmLWnOmxWzS4AAoCwISQDEpLCGkDSC4wl5OReR2s4yr2Q3xYd0Zu5yro9BhgAkMgIyQCFpPhqw76YepQ1GTnHbXNWF5vblAEGOOwKIFERkgELSWENPrnPUXf05FlbGykys4hfpPdo7fUO57ArgARFSAYwJEuPnLIFYM8J64z1Ek7Tvtxhq5OZPOLF+jo47AogERGSAQxJMXae/V7HKUvt4ShlxGeb9Kf5Sj/sCgCJhpAMaEieqzyvuo9bExWMkbIkf6/+FN9J79H6mgAg0RCSAQ3JCD0cpcioOkGRxnRaABIYIRnwkKy8kDr/OznPCCG3Rs5xG4ddASQqQjLgISnOX+idBXmsVA67AkhUhGQIQjIMrIddGdcVQKIgJAlJ11h7kwwwACAREJKEpGsYYABAoiEkCUlXcdgVQCIhJAlJ11kPux45zmFXP1VVnVcbdgX3Ii8gbAhJQtJ1L3HYNS4+Xb5LpYxYbvzeX59U8zlJAUQjJAlJT1h7kxx29c66bYfM+2j18gZBCdQZIUlIeuK/Bn1p22HDfVlrSqKCUS8yvCGA2iMkCUlP6NNpjfiMw65ukPONj/VbEhWGUobO3KAKvzuqXhm31rZ+4Mff6D8GQIwISULSU9adNeO61o5c/PSXIV9FhaIU+SKy8Os9+lPUsVP2OUeHfLpBbwIgBoQkIekp62HXz1cV69W4jO17jqnW/ZdGhaOUAR8X6M1tuqSvsrWX4Q0B1AwhSUh6isOuNXf81Dn13P+/SlUvf3tnpTpVUak/xdHfL7S3Pv/dOVv0JgAugZAkJH1h3VFz2DWaXKXax+Eq1ScHZqvdB07oT4nZ/vLTtp/3wYJtehMADghJQtIXHHZ1dqmrVOW+R+lZ1lXk/slIARAbQpKQ9AXTadld6ipVOQe5bc9R/Sl19t9Dl9m2M+3LnXoTABpCkpD0zYjP7OO6Jtth18tdpbooL/oqVbcV7Ttu2+6slbv1JgAsCElC0jcyfVayHnaVnqHTVap+38fYbnCObfsAnBGShKSvku2wq9PFOHLV6ekaXKXqtrZvV39ZebTvErVgvfe92Lr6tuiI6vref25rceM8LRALQpKQ9J3cBhLZQSfyuK4nz5yzBaNcpVpch6tU3SahY319X35TqjcJhLPnqtRTb2VHfdHoMGyZ3hRwHSFJSPpODrtad3aJ6sOF28z3KBfNBLH302Zgdfg83m+JXh13uVsOqP8ZuSIqICOlYOcR/SmAq0ITkkuXLlX16tVTXbt2Ndfl5uYa66Q0a9bM0jp2hGR8JPoAA4P//a35/vpOzderA8V6rlQeryk8qDfx3akzlVHncOVqYBkM4b25W2zrM3O5+AjeCU1I/uIXv1B33XWX6tKli7mucePGKjMzUxUVFamGDRuqysqan+MhJONj0+4y245OlhOJ9b0F6RDrxay60Ft73BJITwxYqjfx1eK8vVG3q0jZUXrMbKPXjfui0PITAPeEIiRLS0tVt27dVElJiRmSEohNmzY120iv0trLjFVaWprKyMigxKGMmzjFtqPT68NaBqTPMN9T634Lo+qDWh7tW/23eLzvIjX0/elRbbwsLw7/PCr8HrvwOnqMzIxqK2XI2E9sbZ8bNFd9MHFyVLtkKPBOKEKyfv36xr/WkCwoKDCC06pFixa25VjQk4yvl8dWH3Z9+5Nv9erQmbG8yLbjlotOwkSudLW+/i0l5XoT1+XvOBwVjlLWbrv8Yd99ZfYh96TUZQg/QBf4kKyqqlL33nuv8dgakjk5OapXr17Wpqp58+a25VgQkvG1teSobQcXdm1DPtn0F+u+s71+eT9eGjj9m6iQe/rtL9Wny3fpTR29Ot4+f+Yzg3P0JkCtBT4kb775ZpWammqU119/Xd13331q27ZtRmC2a9fObHfo0CHVvn17yzNjQ0jGn3UUmilLd+jVoVF88KRtZ7252PtemFes76Ndao7aue+43qROlm3cHxWOL49dU+vfmX7/rVzk8/nq5BmsAt4JfEhaWXuSQq5qjWjbtq1RX1OEZDD8nw/Xmzu4NyZ9rVeHgnUnXXrklF4dOtNzdtreU8mFLwF1NXbe1qhwlFtPjp925/YYmYDa+rOHzUq8K6fhr1CHZKNGjVR6errKysqyBWZNEJLBIOeRrDu3sJEJjcP8+p1Y31Ndbt6X38/89fZDuVJe++hrtWu/u71UfeABuZ0EqK1QhaSQc5RW5eXltepBRhCSwfF8WvV0TmMu9DjC4szZKiNAIq997prafx6DyBo48jeS+SlrQnpzejjKIAbye/PKC6Psk013TFuhNwFiErqQdBshGSzWHVv3cWv06kCy9lzWBuBGfC+kZ9lv4D98rEJvEkXGp9XD8R/v5urNPCNj41q3LcMCAjVFSBKSgaIfKguDsL3e2rK+z06jLx12/abmRwWkXClb6fP8aGmZ1dOzSZm3NrF6+fAeIUlIBorsRP+R/p+ZHqQMnblBbxIovSdWX3A0avZmvTqh6OddZUaOY6fO2to8Ozx6pJx/jl9ra+M3CUZ9gusqn8Ma4UVIEpKBZN2hnasM5g5NAt36OpOBhIt+b6NcyauHkJQPFmwL1EUzciuL9fWVn7AHPHAxhCQhGUjWiYGnf7VTrw4EGVg78hqlB5Us5EuLHoh6eTMjT39a3MktLNbXKBf37Dkc/lt14C1CkpAMrFc/qB5JJWgzaYybX2i+NrkJPtnIcHt6MEqReyuDPBSf9GzlPlzra07Ui63gDkKSkAysHaXHbTuzILFO4ySTFycj6/lYKakzwjH2rt4TDuI8mggOQpKQDDTrhSByjisINuyqnuZLpphKdmH9kqCfR33n88S+8Aq1Q0gSkoFn3ZEFgfX16Fd3IlysX3ikyGDpR0/yN0U1QpKQDDwZnSWyE5OxOeOpQjsXh/BLGVE90pMUGQQBiPA1JCsqKtSSJUuMSUIXLlyozsuNV3FGSAafnEOyjt4ycvYmvYkvjhyvMKZxiryOlZv3600QUvr5Vfk7A8LTkNy3b5/q06ePMfj4pco111yjiovjM60NIRke1p1YPG4Gt57DKvzuqF6NkNMHS5AyY1mR3gxJxtOQHDJkiBmEt99+uzEf5MyZM40Jk999912VkpKifvKTnxj1r7zyiv50XxCS4WGd0Hjmitgn5XWLdeeJxDRr5W71aF/7BT0BOOCFOPI0JMOAkAwPfWJdP8nA3JHtZiz5v3o1Eoz1C5mUeBy5QDDENSSlB3nTTTfpq31FSIbLe3OrZ6PoOHKFcSGN1+QG9HiFM+Kns+WL0RMDlqpd+0/oTZAE4h6SDRo00Ff7ipAMlxOnz6m/Dv3K3HlN8qFXN3HRdnN7Mqg3ksPxU+fUS2NWm3/7sEzdBnfFNSSDgJAMJ796dqmfbjC3868pwRoaD/6wftaKD57Uq5HgfA3JwsJC83H37t3V/PnzLbXxQUiGk5wXjOy4pGfpFb/CGMG1c19wh0eE93wNSTm8KrZu3Wpe9fr+++9rrfxFSIaTHzf1L9uwz/z5bblvLqlZP2symwiSh68heffddxv3TjZs2FCNGjVK3XPPPWZwxgshGV5vWeY17Pb+GuPqVzdZd4xBntkC3ttReswYpzfyeZBbRZAcfA1J6wAC4mc/+xkhiTqRnZXZ2xv0pV5da2PmbjV/7ivj1urVSEL67CHcP5kcfA3Jli1bGqH4yCOPGMvy+P7779da+YuQDDe5f82643KDHE6z9ho27S7TmyBJWT8XMuk2Ep+vIRnvXuPFEJLhN2r2ZnPH5cbg1NbQLT3CzPWopvcmkfgISUIy9GS6Krd2XPr4nYBOJmmOfD4+Xx2fMafhH19D8te//rW68sor1V133WUWuXgnngjJxNBzwjpzx/W/k/P06picOVulOgyrnuR5DjtAXIT0Jq3DFL720dd6EyQQX0PyT3/6U1R56qmn9Ga+IiQTx4SF28wd17PDl+nVl/XUW9XzVtKLxOVYPyv7y07r1UgQvoZkEBGSieN0Rd3GWLU+l94BLqfT6Ore5OuT+LwkKl9DUs5JPvTQQ2rMmDF6VdwQkoml79R8c8f16vjYb92QUIw8b2RmfCZ1RvjYepPl9CYTka8huWnTJvWb3/zGvFdSBhX485//rI4ejd8EtoRk4rHuuNoNztGro1R6cBsJkoPcHmSdjHv++u/0Jgg5X0Myori4WD3wwANmWF599dVqw4YNejNfEJKJx3oYLJbQ+3xVsdm2NucykdzGzy80Pz9uDmiBYPA1JNesWaNuueUWMxx/8IMfqL59+6pWrVqpp59+Wm/uC0IyMQ2btdHccf0j3Xl6qw8WVF/s8/LY1Yyiglp5tG91b3Lh13v0aoSYryEpwXjvvfeqsWPH6lVxQ0gmLmtv0ul8UU16nIATuX3I+lliWrXE4WtIvvbaa/qqmJw6dUrNnDnT6InqZPqtrKwsfXXMCMnEJWOuRnZa/acV6NVq4+4ys16GGwPqwtqb5EtX4vA0JC/8XKP3+OSTT6rJkyers2fP2up37dqlpkyZoho3bqxeeuklW13EkSNH1JtvvmmE4RtvvKGaNGli1snzMjMzVVFRkXERUGVlpeWZsSEkE9vYedUDlT+fttxWZ92hHT1p/2wCNSW3IHUcucL8TPW7yBczhI+nISn27t2rbr/9dvM85MVKjx499Kc5kvZCArFp06bm+tzcXNW1a1dzOVZpaWkqIyODksDFGoajP5hmrOs96jNz3TMDF0Q9h0KpbbF+3sZNnBpV70WBdzwPyYiCggKVkpJiTI8lF+zIrSCpqalq1Srniyp0X3/9tfrtb39rPC4tLTV+XkRZWZlq3bq1uRwrQjLxS8fBc82d1nOD5l3YcU1RT/RbZK57670ZUc+hUGpb2g6Yb362/j4kK6reiwLv+BaSdXHjjTcaPchGjRqp9evXG+tycnJUr169bO2aN29uW44Fh1uTg/XbvXWA6q3fxe8eXSSu0XOqZ6Zpl3r5e3URXKEISSE9xQ8//NA49yjy8/NV586dbW1kvsqaIiSTwwujVtqCMlIAL5w6U7chEhEcoQnJiMg5yYqKCttFPIsWLTIO39YUIZk8Bv37W9uOa9Li7XoTwDXWeU7/MuQrvRohEfiQHD16tOrZs6eaPXu2+uc//6luuukms04Ov6anpxu3gETCs6YIyeTCt3v4yfp5W75xv16NSzh48KBavTr+0eR7SPbu3Vv99a9/NR6vXLnS+EVcyp49e9Q111xjhKDMRbl582azLjs7W9WvX9+o69Onj+VZsSMkk0ufyXnGDkv+BbyWlrnJ1pvkVqPYtWjRotadHzf5GpLyhq+99lrzvOLNN9+srrjiCq2VvwhJAF5aU3gw1EcwtpYcVelZWzwtMpRflTYkpHSApk6dGnWBpt98DUkJRXHbbbcZ//7ud7+L+zcFQhKA1zoMW2aG5NCZ8ZnMoTYkwKwB72VpMzDb3K6Mrvbuu+8aj60Zcf78eWNCjG7duhmn3h5++GHjlJv4/PPP1S9/+Uv1+9//3njOsWPHzOfVha8hKecQRSQkr7/+ekISQMJbtfWALRDCYsayoqgw86r8/Z2V5nZffvlltW/fPuOxNSNk0Jh33nnHeLxs2TLVv39/47EMXfqjH/1InTlzxliWkdzeeust83l14WtI3nrrrbaRdqR8+umnejNfEZIA/PDfQ6t7k8NnbdSrA63sREWNypHjNSs6azAOHDhQTZ8+3Xgsg890797deCzXtESCcPjw4cZz/vjHP5rlrrvuMn9GXfgakjL7x7lz59T27dvV4cOHjXUyfquMnhMvhCQAv6R+usEMSjkEi2hymPTnP/+5cS4yUuSizQMHDhg9xEmTJqnnn3/edsvfxIkTPTsq6WtIypv46KOPjOHlxMcff2y8+ciFPPFASALwi1zdaj3EiGiSEePHj7etk+yQ2wFlnO+1a9fa6sTGjRuNC3284HtIyvlI+XfevHnGvzLkXJs2bdSQIUP05r4gJAH4yTqoRcpw+8w0ya68vFw1aNBAX60eeughIy9kONIXXnjBmFVKZoeSdQsWLDDayPnI6667zlgnP+NiUyvWhq8hKbOBiLy8PNWhQwfjzfztb39T+/fvN4IyHghJAH6z9ibXbz+kV8PBD3/4Q2P6xAjJkAkTJlhauM/XkJTusATkU089JRs2T7TOmTPH+HYQD4QkAL+9Nf2b6t7kiOXGWK+4PMkNuQD0scceUw8++KB65JFHjOtcvORrSMpVShKMt9xyizGKzt13321cgSTriouL9ea+ICQBxEPOt6WcnwwBX0NSRIahk3+PHj1qHGpt37691so/hCSAeLGG5KkKepNB5HtIRsh9L1dddZVnl+3GipAEEC9LC+y9yYKd1efbEAy+hWRVVZXq1KmTEYqRIodb5RBsPBGSAOLpmcE5HHYNMF9C8tVXXzWuSrIGZLx7kBGEJIB4WpK/1xaS3xTRmwwSz0NS5gOTQLzjjjvMi3PkXCQhCQD/cejYGXqTAeV5SJ4+fdoYrT3Se7z33nvVgAEDCEkAsBgzb6t6tO8SNfbCvwgOz0NSyH0sX3zxhTkaQqTIALUy9Uk8EZIAguJig30jvnwJSZ0cbm3VqlUgzk0SkgAAJ3EJySAhJAEATghJQhIA4ICQJCQBAA4ISUISAOCAkCQkAQAOCElCEgDggJAkJAEADghJQhIA4ICQJCQBAA4ISUISAOCAkCQkAQAOCElCEgDggJAkJAEADghJQhIA4CAUIXnmzBk1a9YslZeXp1epwsJClZWVpa+OGSEJAHASipC84YYbzLkn161bZ67Pzc011zdr1szyjNgRkgAAJ4EPyfPnz5uPq6qqbJM0Wx/36NFDLV682FyOFSEJAHAS+JDURYKxtLRUpaSkmOvLyspU69atzeVYpaWlqYyMDAqFQgltgXdCFZJyePXBBx80HhcUFKhu3brZ6lu0aGFbjgU9SQCAk9CEZKdOnWyHV/Pz81Xnzp0tLZRq2bKlbTkWhCQAwEkoQnLcuHGqTZs2qrKy0lxXUVGhmjRpYi4vWrRIpaammsuxIiQBAE5CEZINGjQwQlFn7Vm2bdtWlZSUWGpjQ0gCAJwEPiSlhxi5zSNSIrKzs1X9+vWNdX369LE8K3aEJADASeBD8nLKy8tr1YOMICQBAE5CH5J1RUgCAJwQkoQkAMABIUlIAgAcEJKEJADAASFJSAIAHBCShCQAwAEhSUgCABwQkoQkAMABIUlIAgAcEJKEJADAASFJSAIAHBCShCQAwAEhSUgCABwQkoQkAMABIUlIAgAcEJKEJADAASFJSAIAHBCShCQAwAEhSUgCABwQkoQkAMABIUlIAgAcEJKEJADAASFJSAIAHBCShCQAwAEhSUgCABwQkoQkAMABIUlIAgAcEJKEJADAASFJSAIAHBCShCQAwAEhSUgCABwQkoQkAMBBKEKyqqpKNW7cWNWrV8+2Pjc311gnpVmzZra6WBGSAAAnoQjJ++67T/34xz+OCkkJzszMTFVUVKQaNmyoKisrbfWxICQBAE5CEZKie/futpCUQGzatKm5LL3Krl27msuxSktLUxkZGRQKhRLaAu+ENiQLCgpUt27dLC2UatGihW05FvQkAQBOQhuSOTk5qlevXpYWSjVv3ty2HAtCEgDgJLQhWVJSotq1a2cuHzp0SLVv395cjhUhCQBwEtqQFNbltm3bGsFZU4QkAMBJKELy/fffVy1btjRCUR5HNGrUSKWnp6usrKyoAI0VIQkAcBKKkLyU8vLyWvUgIwhJAICT0IdkXRGSAAAnhCQhCQBwQEgSkgAAB4QkIQkAcEBIEpIAAAeEJCEJAHBASBKSAAAHhCQhCQBwQEgSkgAAB4QkIQkAcEBIEpIAAAeEJCEJAHBASBKSAAAHhCQhCQBwQEgSkgAAB4QkIQkAcEBIEpIAAAeEJCEJAHBASBKSAAAHhCQhCQBwQEgSkgAAB4QkIQkAcEBIEpIAAAeEJCEJAHBASBKSAAAHhCQhCQBwQEgSkgAAB4QkIQkAcEBIEpIAAAeEJCEJAHBASBKSAAAHhCQhCQBwEPqQLCwsVFlZWfrqmBGSAAAnoQ7Jxo0bq8zMTFVUVKQaNmyoKisr9SaXRUgCAJyEOiTr1atnPu7Ro4davHixpTY206ZNUydPnqRQKJTQltp0EBCb0IZkaWmpSklJMZfLyspU69atLS1ik56ernJzc30ribw92Zbf29PXeVnYnruF7blXJkyYoO/a4JLQhmROTo7q1auXbV3z5s1ty7HIyMjQV3kqkbcn2/J7e35ie+5ie+7xc1vJJrQhmZ+frzp37mxb17JlS9tyLPz+cCXy9ghJd7E9dyXy9vzcVrIJbUhWVFSoJk2amMuLFi1Sqamplhax8fvDlcjbIyTdxfbclcjb83NbySa0ISkaNWpkHPeXW0CsF/EAAOCGUIdkdna2ql+/vhGQffr00asBAKiTUIckAABeIiQBAHBASAIA4ICQBADAASEJAIADQhIAAAeEZC0tW7ZMX+UJmeFkzpw5au/evXqVJ7Zv367mz5+viouL9SrPbNu2Ta1Zs0Zf7YnNmzeb5dixY3q1J5YuXao+++wzfbWrTpw4YXtvUuRv6bUtW7YYA3n44fjx42rVqlXGe/PS+fPn1Y4dO/TVxudlxYoV+uo6W7169UW3J/zaz8AZIVlDVVVV6p133vFl8ALZGch2pDRo0MD4z+ulTZs2+bq9iMg2vbZkyRJzW1IGDhyoN3Hd448/bm6vb9++erVrhg0bZntvfvxO77//fnM7zz//vDp37pzexDXy/06mw4tsT74UeEG+WDz00EPqySeftK1/7rnnjP8Tsu3hw4fb6upCtic/U9+en/sZXBohWUN/+MMfzPDy2u7du83HkydPVo899pil1n2HDh0yH8+ePVt17NjRUuuNESNGqHnz5vny+5QeucyY4JdXXnmlVtO3uWHu3Lnqtdde01e7Rj6bTzzxhLl8sR29m77//e+rs2fPmstXXXWV7fPqhnXr1qmRI0eqAwcO2N6LHMV5+umnzeWrr75atWjRwlyurcj2Lva783M/g0sjJGvJ7w+vTA79wgsv6Ks9IT3Itm3bqi+++EKvcp3s/EpKSnz5ffoZkgUFBeZ78qrX40QG//fj9ynbGD16tDFtnUyAXlhYqDdxjf5+Itv2gky7Zw0tmUhh586d5nL37t2jXk9dXCwkI9zcDmqHkKwlvz+8Dz/8sDEMn9dGjRql7rnnHnXDDTfoVa5buXKl+vDDD30LSRnj98orr1Q33XSTcajQy8PJM2bMMN6T9Ajk31tvvdU4p+YHmWfVj9/ngw8+aGxHvujIuUIv3XjjjerIkSPmsmz37bfftrRwjx6Sbdq0sW27f//+rv5+CclgIyRryc8Prxx2ue222/TVnvnmm2+Mc2lO/3HdMHbsWOMcj/ArJK0OHz5sjPvrFQl//T15uT0r2e7UqVP11a6T7Tz77LNqzJgx6tprr/X80PIjjzxizPwj5z9l2+PHj9ebuEIPSTmsLL3lCDmXrf9t64KQDDZCspb8+vA2a9ZMXXPNNfpqX8h7XL58ub7aFdIzkAsxpEjvTrYlj/3k5d/wYoc89WUvvPfee2rAgAH6atd16dJFbdiwwVzu0KGDL+8vQj4/Z86c0Ve7Qg/JQYMGGdcERDzwwAOuHmkhJIONkKwlPz68csm5XCSwcOFCvcoTcrtJRHl5udHTk3+95ldPUq4YjJCLPq677jpLrbvkIpPvfe97xrynQg61en00QN7fnXfeqfbv369Xua5nz57G1ZcR0sO74oorLC28M23aNNW7d299tWv0kJQrUFu1amUenpf/F506dTLr64qQDDZCsobkQ2stt99+u97ENXIFnb49uYDHKxMnTjS3I+fQKisr9SaekKsH/dgZyI5dtiOHPX/1q1/p1a6T0JIvObLNO+64Q692nRyOlF65X5o3b25+Xt544w11+vRpvYlr5ErhyLbk7+gF+ZKo/3+bNGmSUSeHeK+//nrjqlq37tO81Pb09V7uZ3BphCQAAA4ISQAAHBCSAAA4ICQBAHBASAIA4ICQBADAASEJAIADQhIAAAeEJAAADghJAAAcmCG5Y8cORaFQKBQKpboYITlkyJAfpaamtqJQKBQKhVJdJB//H6d8iAolk9x0AAAAAElFTkSuQmCC>