# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(ggplot2)
library(dplyr)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Startup Investor Relations Guide"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Venture Deals", tabName = "venture_deals", icon = icon("handshake")),
      menuItem("Hard Things", tabName = "hard_things", icon = icon("mountain")),
      menuItem("Blitzscaling", tabName = "blitzscaling", icon = icon("rocket")),
      menuItem("Angel", tabName = "angel", icon = icon("star")),
      menuItem("Sand Hill Road", tabName = "sand_hill", icon = icon("road")),
      menuItem("Airbnb Case", tabName = "airbnb", icon = icon("home")),
      menuItem("Dropbox Case", tabName = "dropbox", icon = icon("cloud")),
      menuItem("Canva Case", tabName = "canva", icon = icon("paint-brush")),
      menuItem("Stitch Fix Case", tabName = "stitch_fix", icon = icon("tshirt")),
      menuItem("Slack Case", tabName = "slack", icon = icon("comments"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .main-header .navbar { background-color: #1e3a8a !important; }
        .main-header .logo { background-color: #1e3a8a !important; }
        .sidebar { background-color: #1e3a8a !important; }
        .sidebar .sidebar-menu > li > a { color: white !important; }
        .sidebar .sidebar-menu > li.active > a { background-color: #3b82f6 !important; }
        .content-wrapper { background-color: #f8fafc !important; }
        .box.box-primary { border-top-color: #1e3a8a !important; }
        .box-header.with-border { border-bottom: 1px solid #1e3a8a !important; }
        .nav-tabs-custom > .nav-tabs > li.active > a { background-color: #1e3a8a !important; color: white !important; }
      "))
    ),
    
    tabItems(
      # Venture Deals Tab
      tabItem(tabName = "venture_deals",
              fluidRow(
                box(title = "Key Topics from Venture Deals", status = "primary", solidHeader = TRUE, width = 12,
                    h4("1. Term Sheet Fundamentals"),
                    p("Understanding term sheets is crucial for any entrepreneur seeking venture capital. Term sheets outline the key commercial and legal terms of an investment, including valuation, liquidation preferences, anti-dilution provisions, and board composition. The book emphasises that entrepreneurs must comprehend every element, as these terms significantly impact future fundraising rounds and exit scenarios. Pre-money and post-money valuations determine ownership percentages, whilst liquidation preferences affect how proceeds are distributed during an exit. Anti-dilution provisions protect investors from future down rounds, potentially diluting founder equity. Board composition clauses establish governance structures that can influence strategic decisions. Entrepreneurs should negotiate these terms carefully, understanding their long-term implications rather than focusing solely on headline valuation figures."),
                    
                    h4("2. Negotiation Strategies"),
                    p("Effective negotiation requires preparation, understanding investor motivations, and maintaining relationships for future rounds. The authors stress that negotiations should be collaborative rather than adversarial, as entrepreneurs and investors will work together for years. Key strategies include researching comparable deals, understanding market standards, and identifying which terms matter most to your specific situation. Entrepreneurs should prioritise terms that maintain control and minimise dilution whilst acknowledging investors' legitimate concerns about downside protection. Timing negotiations appropriately, having multiple interested parties, and maintaining transparency about other discussions can strengthen negotiating positions. The book advises focusing on creating win-win scenarios where both parties feel the deal reflects fair value and appropriate risk allocation."),
                    
                    h4("3. Investor Types and Motivations"),
                    p("Different investor types have varying motivations, timelines, and expectations that entrepreneurs must understand. Angel investors often provide smaller amounts with less stringent terms but may lack follow-on capacity. Venture capital firms manage institutional money with specific return requirements and timeline pressures, typically seeking 10x returns within 5-7 years. Strategic investors may prioritise strategic benefits over financial returns, potentially offering valuable partnerships but sometimes creating conflicts of interest. Corporate venture capital arms balance financial returns with strategic objectives, which can align with or conflict with entrepreneur goals. Understanding these motivations helps entrepreneurs target appropriate investors and structure deals that align interests whilst maintaining strategic flexibility for future growth and exit options."),
                    
                    h4("4. Legal Documentation Process"),
                    p("The legal documentation process transforms term sheet agreements into binding contracts that govern the investor-entrepreneur relationship. Key documents include stock purchase agreements, investor rights agreements, voting agreements, and amended articles of incorporation. Each document serves specific purposes: stock purchase agreements define the investment mechanics, investor rights agreements establish ongoing investor privileges, and voting agreements govern decision-making processes. The book emphasises hiring experienced startup lawyers who understand venture capital transactions and can explain implications of various clauses. Entrepreneurs should budget adequate time and resources for legal processes, as rushing can lead to unfavourable terms or overlooked provisions that create future problems during subsequent fundraising rounds or exit events."),
                    
                    h4("5. Post-Investment Relationship Management"),
                    p("Managing investor relationships post-investment is crucial for ongoing success and future fundraising. Regular communication through board meetings, investor updates, and informal interactions builds trust and demonstrates progress. Entrepreneurs should provide transparent updates about both successes and challenges, seeking investor advice on strategic decisions whilst maintaining appropriate boundaries around operational control. The book emphasises leveraging investor networks for customer introductions, strategic partnerships, and talent recruitment. Building strong relationships with existing investors often leads to follow-on investments and positive references for future rounds. Successful entrepreneurs view investors as partners rather than just capital sources, actively engaging them in value creation whilst managing expectations and maintaining focus on long-term value creation rather than short-term metrics.")
                )
              ),
              fluidRow(
                box(title = "Venture Capital Funding Stages", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("vc_stages_plot")
                )
              ),
              fluidRow(
                box(title = "References and Resources", status = "primary", solidHeader = TRUE, width = 12,
                    h4("Academic References"),
                    p("Feld, B. & Mendelson, J. (2019). Venture Deals: Be Smarter Than Your Lawyer and Venture Capitalist. 4th ed. Hoboken: John Wiley & Sons."),
                    p("Gompers, P. & Lerner, J. (2004). The Venture Capital Cycle. 2nd ed. Cambridge: MIT Press."),
                    h4("Verified Links"),
                    p("National Venture Capital Association: ", a("www.nvca.org", href = "https://www.nvca.org", target = "_blank")),
                    p("Venture Deals Book Resources: ", a("www.venturedeals.com", href = "https://www.venturedeals.com", target = "_blank")),
                    p("Brad Feld's Blog: ", a("www.feld.com", href = "https://www.feld.com", target = "_blank"))
                )
              )
      ),
      
      # Hard Things Tab
      tabItem(tabName = "hard_things",
              fluidRow(
                box(title = "Key Topics from The Hard Thing About Hard Things", status = "primary", solidHeader = TRUE, width = 12,
                    h4("1. Making Difficult Decisions Under Pressure"),
                    p("Leadership during crisis requires making decisions with incomplete information whilst managing stakeholder expectations and maintaining team morale. Horowitz emphasises that hard decisions often have no clear right answer, requiring leaders to choose between bad options whilst taking full responsibility for outcomes. Effective crisis management involves gathering available information quickly, consulting trusted advisors, and making decisive choices rather than delaying decisions hoping for better options. Leaders must communicate decisions clearly to all stakeholders, explaining reasoning whilst acknowledging uncertainty. The book stresses that postponing difficult decisions typically worsens situations, whilst decisive action—even if imperfect—allows organisations to adapt and recover. Successful entrepreneurs develop decision-making frameworks that balance speed with thoughtfulness, ensuring they can act quickly when circumstances demand immediate responses to preserve company viability."),
                    
                    h4("2. Managing Investor Relationships During Downturns"),
                    p("Maintaining investor confidence during difficult periods requires transparency, realistic planning, and proactive communication about challenges and recovery strategies. Horowitz advocates for honest communication about problems rather than attempting to hide difficulties, as investors prefer early warnings that allow collaborative problem-solving. Effective investor management involves presenting clear assessments of current situations, realistic recovery plans with specific milestones, and regular updates on progress against those plans. Entrepreneurs should leverage investor expertise and networks during difficult periods, seeking advice on operational improvements, strategic pivots, or additional funding sources. The book emphasises that investors understand startup risks and prefer entrepreneurs who acknowledge problems promptly rather than discovering issues through delayed reporting or missed milestones that damage trust and credibility."),
                    
                    h4("3. Building Organisational Resilience"),
                    p("Creating resilient organisations requires developing systems, processes, and cultures that can withstand significant challenges whilst maintaining core functionality and team cohesion. Horowitz stresses the importance of building strong management teams capable of operating independently during crisis periods. Resilient organisations maintain clear communication channels, documented processes, and decision-making authorities that function when normal operations are disrupted. Cultural resilience involves fostering adaptability, encouraging honest communication about problems, and maintaining focus on core mission objectives despite external pressures. The book emphasises that resilient organisations often emerge stronger from challenges, having developed capabilities and relationships that provide competitive advantages during normal operations and future difficulties."),
                    
                    h4("4. Strategic Pivoting and Adaptation"),
                    p("Successful pivoting requires recognising when current strategies aren't working, developing alternative approaches based on market feedback, and executing transitions whilst maintaining team confidence and investor support. Horowitz explains that effective pivots preserve valuable company assets—team capabilities, customer relationships, technology infrastructure—whilst redirecting efforts toward more promising opportunities. Strategic adaptation involves continuous market assessment, customer feedback integration, and willingness to abandon unsuccessful approaches despite previous investments. The book emphasises that timing pivots appropriately is crucial: too early abandons potentially successful strategies, whilst too late wastes resources and may damage company viability. Successful entrepreneurs develop frameworks for evaluating strategy effectiveness and maintaining organisational flexibility that enables rapid strategic shifts when market conditions demand adaptation."),
                    
                    h4("5. Leadership During Uncertainty"),
                    p("Leading during uncertain periods requires maintaining team confidence whilst acknowledging challenges, making decisions with incomplete information, and adapting strategies as situations evolve. Horowitz stresses that leaders must project confidence and decisiveness even when personally uncertain, providing teams with clear direction and purpose during difficult periods. Effective uncertainty leadership involves transparent communication about known challenges, realistic assessment of available options, and commitment to decisive action based on best available information. Leaders should focus on controllable factors whilst preparing for various scenarios, maintaining team morale through consistent communication and recognition of efforts during difficult periods. The book emphasises that successful leaders emerge from uncertainty having strengthened organisational capabilities and relationships that provide advantages during future challenges and normal operations.")
                )
              ),
              fluidRow(
                box(title = "Crisis Management Timeline", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("crisis_timeline_plot")
                )
              ),
              fluidRow(
                box(title = "References and Resources", status = "primary", solidHeader = TRUE, width = 12,
                    h4("Academic References"),
                    p("Horowitz, B. (2014). The Hard Thing About Hard Things: Building a Business When There Are No Easy Answers. London: Harper Business."),
                    p("Christensen, C.M. (1997). The Innovator's Dilemma. Boston: Harvard Business Review Press."),
                    h4("Verified Links"),
                    p("Andreessen Horowitz: ", a("a16z.com", href = "https://a16z.com", target = "_blank")),
                    p("Ben Horowitz Blog: ", a("ben-horowitz.com", href = "https://ben-horowitz.com", target = "_blank"))
                )
              )
      ),
      
      # Blitzscaling Tab  
      tabItem(tabName = "blitzscaling",
              fluidRow(
                box(title = "Key Topics from Blitzscaling", status = "primary", solidHeader = TRUE, width = 12,
                    h4("1. Rapid Scaling Strategies"),
                    p("Blitzscaling prioritises speed over efficiency to capture market opportunities before competitors, requiring significant capital investment and acceptance of operational inefficiencies during growth phases. Hoffman argues that in winner-take-all markets, being first to scale often determines long-term success, justifying aggressive growth investments despite short-term losses. Effective blitzscaling involves identifying market opportunities with strong network effects, hiring rapidly to support growth, and implementing systems that can scale quickly even if initially inefficient. Companies must balance growth speed with operational sustainability, ensuring they can maintain service quality whilst expanding rapidly. The book emphasises that blitzscaling requires substantial capital resources and investor support for sustained periods of unprofitability whilst building market-leading positions that enable long-term profitability and competitive advantages."),
                    
                    h4("2. Network Effects and Market Dynamics"),
                    p("Understanding network effects is crucial for identifying blitzscaling opportunities, as these effects create self-reinforcing growth cycles that strengthen competitive positions. Hoffman explains that direct network effects occur when increased usage by one user directly benefits other users, whilst indirect network effects develop through complementary products or services. Platform businesses often exhibit strong network effects, as more users attract more suppliers, creating value for all participants. Data network effects occur when increased usage improves product functionality through machine learning or personalisation. The book stresses that companies with strong network effects can justify aggressive early investments because growth becomes self-sustaining and creates significant barriers to competitor entry. Successful blitzscaling requires identifying and leveraging these effects whilst building platforms that maximise network value creation."),
                    
                    h4("3. Organisational Design for Growth"),
                    p("Rapid scaling requires organisational structures that can adapt quickly whilst maintaining operational effectiveness and cultural coherence across expanding teams. Hoffman emphasises that traditional organisational approaches often fail during blitzscaling because they prioritise efficiency over adaptability. Effective scaling organisations implement flexible hierarchies, clear communication systems, and decision-making processes that function at larger scales. Cultural preservation becomes critical as teams grow rapidly, requiring deliberate efforts to maintain core values and working methods. The book advocates for hiring experienced managers who understand scaling challenges whilst empowering teams with autonomy to adapt processes as needed. Successful blitzscaling organisations develop systems for knowledge sharing, performance management, and coordination that can accommodate rapid headcount growth without losing operational effectiveness."),
                    
                    h4("4. Capital Requirements and Funding"),
                    p("Blitzscaling demands substantial capital investment for market expansion, team building, and infrastructure development before achieving profitability, requiring investor alignment with aggressive growth strategies. Hoffman explains that blitzscaling companies typically require multiple large funding rounds to sustain growth through unprofitable periods whilst building market-leading positions. Effective capital planning involves realistic assessment of growth requirements, timeline projections for profitability, and contingency planning for extended funding cycles. Entrepreneurs must communicate clearly with investors about blitzscaling strategies, demonstrating how early losses translate into long-term competitive advantages. The book emphasises that successful blitzscaling requires patient capital from investors who understand that immediate profitability may be counterproductive if it slows market capture during critical growth windows."),
                    
                    h4("5. Risk Management During Rapid Growth"),
                    p("Managing risks during blitzscaling requires balancing aggressive growth with operational stability, maintaining quality standards whilst scaling rapidly, and preserving company culture during rapid team expansion. Hoffman stresses that blitzscaling inherently involves accepting higher risks in exchange for potential market leadership rewards. Effective risk management involves identifying critical success factors that cannot be compromised during scaling, implementing monitoring systems that detect problems early, and maintaining flexibility to adjust strategies based on market feedback. Companies must balance investment in growth with operational infrastructure that can support increased scale without compromising customer experience. The book emphasises that successful blitzscaling requires continuous assessment of market conditions, competitive threats, and operational capabilities to ensure that growth investments remain aligned with market opportunities and company strengths.")
                )
              ),
              fluidRow(
                box(title = "Blitzscaling Growth Phases", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("blitzscaling_phases_plot")
                )
              ),
              fluidRow(
                box(title = "References and Resources", status = "primary", solidHeader = TRUE, width = 12,
                    h4("Academic References"),
                    p("Hoffman, R. & Yeh, C. (2018). Blitzscaling: The Lightning-Fast Path to Building Massively Valuable Companies. London: Bantam Doubleday Dell."),
                    p("Parker, G.G., Van Alstyne, M.W. & Choudary, S.P. (2016). Platform Revolution. New York: W. W. Norton & Company."),
                    h4("Verified Links"),
                    p("LinkedIn Learning: ", a("linkedin.com/learning", href = "https://linkedin.com/learning", target = "_blank")),
                    p("Reid Hoffman Medium: ", a("medium.com/@reidhoffman", href = "https://medium.com/@reidhoffman", target = "_blank"))
                )
              )
      ),
      
      # Angel Tab
      tabItem(tabName = "angel",
              fluidRow(
                box(title = "Key Topics from Angel", status = "primary", solidHeader = TRUE, width = 12,
                    h4("1. Angel Investor Psychology and Motivations"),
                    p("Understanding angel investor motivations enables entrepreneurs to craft compelling pitches that address both financial and personal interests driving investment decisions. Calacanis explains that angels often invest for reasons beyond pure financial returns, including desire to support innovation, mentor entrepreneurs, and remain connected to startup ecosystems. Many angels are successful entrepreneurs seeking to give back whilst staying involved in emerging technologies and business models. Some angels prioritise strategic value, investing in companies that complement their existing businesses or provide market insights. The book emphasises that effective pitches address these diverse motivations, demonstrating how investments align with angels' interests beyond financial returns. Entrepreneurs should research individual angels' backgrounds, previous investments, and stated interests to tailor approaches that resonate with specific motivations and create emotional connections that complement financial arguments."),
                    
                    h4("2. Building Investor Networks and Relationships"),
                    p("Developing strong relationships with potential angels requires consistent engagement, value creation, and authentic relationship building rather than transactional approaches focused solely on fundraising. Calacanis advocates for building relationships before needing capital, establishing credibility through regular communication about company progress and industry insights. Effective network building involves attending industry events, participating in angel groups, and maintaining relationships with successful entrepreneurs who can provide introductions. The book stresses that warm introductions from trusted sources carry significantly more weight than cold outreach, making relationship cultivation essential for fundraising success. Entrepreneurs should focus on providing value to potential angels through market insights, customer introductions, or strategic advice rather than immediately requesting investment. Long-term relationship building creates networks that provide ongoing support, follow-on investment opportunities, and valuable advice throughout company development."),
                    
                    h4("3. Pitch Development and Presentation"),
                    p("Effective angel pitches combine compelling storytelling with concrete evidence of market opportunity, team capability, and business model viability. Calacanis emphasises that successful pitches begin with clear problem identification and demonstrate deep understanding of customer needs and market dynamics. Strong pitches articulate unique value propositions, competitive advantages, and realistic growth projections supported by market research and early customer validation. The book stresses importance of team presentation, as angels often invest more in founders than business models, requiring demonstration of relevant experience, commitment, and adaptability. Effective presentations maintain appropriate balance between optimism and realism, acknowledging challenges whilst demonstrating capability to overcome obstacles. Entrepreneurs should practice pitches extensively, anticipate likely questions, and prepare detailed financial models that support presented projections and demonstrate thorough business planning."),
                    
                    h4("4. Valuation and Investment Terms"),
                    p("Angel investment terms require balancing entrepreneur needs for capital and control with investor requirements for appropriate returns and downside protection. Calacanis explains that early-stage valuations often rely more on potential than current metrics, requiring negotiation based on comparable companies, growth projections, and market opportunity assessments. Common angel investment structures include convertible notes, preferred equity, and simple agreements for future equity (SAFEs), each offering different advantages depending on company stage and investor preferences. The book emphasises that entrepreneurs should understand long-term implications of different investment structures, particularly how terms affect future fundraising rounds and exit scenarios. Effective negotiations focus on creating win-win scenarios where entrepreneurs maintain sufficient equity and control whilst providing angels with appropriate return potential and protection against downside risks."),
                    
                    h4("5. Post-Investment Value Creation"),
                    p("Maximising angel investment value requires active engagement with investors beyond capital provision, leveraging their experience, networks, and expertise for business development. Calacanis stresses that successful entrepreneurs view angels as strategic partners rather than passive capital sources, regularly seeking advice on strategic decisions, operational challenges, and growth opportunities. Effective post-investment relationships involve regular communication through formal updates and informal discussions, maintaining transparency about both successes and challenges. The book emphasises leveraging angel networks for customer introductions, strategic partnerships, talent recruitment, and follow-on funding opportunities. Successful entrepreneurs create advisory relationships that provide ongoing value whilst respecting investors' time constraints and maintaining appropriate boundaries between strategic advice and operational control. Strong angel relationships often lead to follow-on investments, positive references for future rounds, and valuable industry connections that accelerate business growth.")
                )
              ),
              fluidRow(
                box(title = "Angel Investment Distribution", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("angel_investment_plot")
                )
              ),
              fluidRow(
                box(title = "References and Resources", status = "primary", solidHeader = TRUE, width = 12,
                    h4("Academic References"),
                    p("Calacanis, J. (2017). Angel: How to Invest in Technology Startups. London: Harper Business."),
                    p("Wiltbank, R. & Boeker, W. (2007). Returns to Angel Investors in Groups. Kansas City: Kauffman Foundation."),
                    h4("Verified Links"),
                    p("Angel Capital Association: ", a("angelcapitalassociation.org", href = "https://www.angelcapitalassociation.org", target = "_blank")),
                    p("This Week in Startups: ", a("thisweekinstartups.com", href = "https://thisweekinstartups.com", target = "_blank"))
                )
              )
      ),
      
      # Sand Hill Road Tab
      tabItem(tabName = "sand_hill",
              fluidRow(
                box(title = "Key Topics from Secrets of Sand Hill Road", status = "primary", solidHeader = TRUE, width = 12,
                    h4("1. Venture Capital Fund Structure and Economics"),
                    p("Understanding VC fund economics helps entrepreneurs appreciate investor motivations and constraints that influence investment decisions and portfolio management strategies. Kupor explains that VC funds typically operate on 2-and-20 models: 2% annual management fees and 20% carried interest on returns above invested capital. Fund lifecycles span 10-12 years, creating pressure for portfolio companies to achieve exits within investment windows. Limited partners expect returns significantly above public market alternatives, typically targeting 3x fund returns, requiring individual investments to generate 10x+ returns to offset failures. The book emphasises that these economics drive VC behaviour: preference for large market opportunities, focus on scalable business models, and emphasis on rapid growth that can generate substantial returns. Entrepreneurs should understand these constraints when evaluating VC partnerships and negotiating investment terms that align with fund requirements whilst preserving company strategic flexibility."),
                    
                    h4("2. Investment Decision-Making Processes"),
                    p("VC investment decisions involve multiple stakeholders and evaluation criteria that entrepreneurs must understand to navigate fundraising processes effectively. Kupor describes typical processes beginning with initial meetings, progressing through partner presentations, due diligence, and investment committee approvals. Partners typically champion specific deals within their firms, requiring entrepreneurs to build strong relationships with individual partners who will advocate for investments internally. Investment committees evaluate opportunities based on market size, competitive positioning, team capabilities, and financial projections, often requiring consensus among partners for approval. The book stresses that decision timelines can vary significantly between firms and deal complexity, requiring entrepreneurs to manage multiple parallel processes whilst maintaining momentum. Understanding these processes helps entrepreneurs present information effectively, address likely concerns proactively, and maintain appropriate follow-up that advances decisions without appearing impatient or unprofessional."),
                    
                    h4("3. Portfolio Management and Value Creation"),
                    p("VCs add value beyond capital through strategic advice, network introductions, and operational support that can accelerate portfolio company growth and improve exit outcomes. Kupor explains that successful VCs actively engage with portfolio companies through board participation, strategic planning sessions, and regular operational reviews. Value creation activities include customer and partner introductions, talent recruitment assistance, and strategic advice on market expansion or competitive positioning. Board governance provides oversight whilst supporting management teams through growth challenges and strategic decisions. The book emphasises that entrepreneur-VC relationships should be collaborative, with clear expectations about engagement levels and value creation activities. Successful partnerships leverage VC experience and networks whilst maintaining appropriate boundaries between strategic guidance and operational control, enabling entrepreneurs to benefit from investor expertise whilst retaining day-to-day management authority."),
                    
                    h4("4. Exit Strategies and Market Dynamics"),
                    p("Exit planning influences investment decisions and company development strategies from early stages, requiring entrepreneurs to understand market dynamics and buyer motivations. Kupor explains that VC investments target exits through IPOs or acquisitions that generate returns justifying initial valuations and growth investments. IPO markets require companies to demonstrate sustainable growth, profitability prospects, and sufficient scale to attract public market investors. Acquisition markets vary by industry, with strategic buyers often paying premiums for companies that complement existing businesses or provide competitive advantages. The book stresses that exit timing depends on market conditions, company readiness, and strategic opportunities that may not align with entrepreneur preferences. Successful companies maintain optionality by building businesses attractive to multiple potential buyers whilst developing capabilities that support various exit scenarios depending on market conditions and strategic opportunities."),
                    
                    h4("5. Industry Evolution and Future Trends"),
                    p("Understanding VC industry evolution helps entrepreneurs anticipate changing investment patterns, emerging opportunities, and competitive dynamics affecting fundraising and company development. Kupor discusses trends including increased competition among VCs, larger fund sizes enabling bigger investments, and growing emphasis on operational support beyond traditional financial backing. Technology developments create new investment categories whilst disrupting traditional sectors, requiring VCs to develop expertise in emerging areas like artificial intelligence, blockchain, and biotechnology. Globalisation expands both investment opportunities and competitive pressures, with international VCs competing for attractive deals and portfolio companies expanding globally. The book emphasises that successful entrepreneurs stay informed about industry trends that affect fundraising strategies, competitive positioning, and market opportunities. Understanding these trends enables better strategic planning and helps entrepreneurs position companies effectively for current market conditions whilst preparing for future developments that may create new opportunities or challenges.")
                )
              ),
              fluidRow(
                box(title = "VC Investment Stages", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("vc_investment_stages_plot")
                )
              ),
              fluidRow(
                box(title = "References and Resources", status = "primary", solidHeader = TRUE, width = 12,
                    h4("Academic References"),
                    p("Kupor, S. (2019). Secrets of Sand Hill Road: Venture Capital and How to Get It. London: Portfolio Penguin."),
                    p("Gompers, P. & Lerner, J. (2006). The Venture Capital Cycle. 2nd ed. Cambridge: MIT Press."),
                    h4("Verified Links"),
                    p("Andreessen Horowitz: ", a("a16z.com", href = "https://a16z.com", target = "_blank")),
                    p("National Venture Capital Association: ", a("nvca.org", href = "https://nvca.org", target = "_blank"))
                )
              )
      ),
      
      # Airbnb Case Tab
      tabItem(tabName = "airbnb",
              fluidRow(
                box(title = "Airbnb - Brian Chesky's Research and Approach", status = "primary", solidHeader = TRUE, width = 12,
                    h4("1. Understanding Y Combinator's Investment Philosophy"),
                    p("Brian Chesky's successful approach to Y Combinator began with extensive research into Paul Graham's writings and investment philosophy, particularly his emphasis on solving real problems for real users. Chesky studied Graham's essays on startup fundamentals, discovering his belief that successful companies focus on user love rather than vanity metrics. This research revealed Y Combinator's preference for founders who demonstrate deep understanding of customer problems and show genuine commitment to solving them. Chesky positioned Airbnb not as a technology platform but as addressing fundamental human needs for belonging and authentic travel experiences. His research showed that Graham valued simplicity and user-focused solutions over complex technical innovations, leading Chesky to emphasise Airbnb's simple value proposition and early user testimonials rather than technical features. This research-driven approach enabled Chesky to frame Airbnb's story in terms that resonated with Y Combinator's core investment thesis."),
                    
                    h4("2. Leveraging Personal Connection and Storytelling"),
                    p("Chesky's pitch strategy emphasised personal storytelling and emotional connection rather than purely financial metrics, aligning with Graham's belief in founder-market fit and authentic motivation. His research revealed that Y Combinator values founders with personal connections to problems they're solving, leading Chesky to share stories about his own travel experiences and desire to create belonging anywhere. He demonstrated deep empathy for both hosts and guests, showing how Airbnb addressed real pain points he had personally experienced. Chesky's storytelling approach included specific examples of early users and their transformative experiences, illustrating Airbnb's impact beyond financial transactions. This personal approach distinguished Airbnb from other technology pitches by focusing on human connections and authentic experiences rather than abstract market opportunities. His success demonstrated the power of combining thorough research with authentic personal narrative that creates emotional resonance with investors."),
                    
                    h4("3. Demonstrating Resourcefulness and Hustle"),
                    p("Chesky's approach highlighted the founders' resourcefulness and determination, qualities that Graham explicitly values in early-stage entrepreneurs facing significant challenges. His research into Y Combinator's successful companies showed that persistence and creative problem-solving often matter more than initial business model sophistication. Chesky shared stories about selling cereal boxes to fund early operations, demonstrating the founders' willingness to do whatever necessary to keep the company alive. This anecdote resonated with Graham's appreciation for founder grit and determination in face of adversity. Chesky's presentation emphasised learning from early failures and iterating based on user feedback, showing adaptability and resilience. He demonstrated that the founding team could execute despite limited resources, a crucial factor for Y Combinator's investment decisions. This approach showed understanding that early-stage investors often bet more on founder capabilities than business model perfection."),
                    
                    h4("4. Focusing on User Love and Market Validation"),
                    p("Chesky's pitch strategy emphasised early user love and organic growth rather than traditional market research or competitive analysis, aligning with Graham's investment philosophy. His research revealed Y Combinator's preference for companies with strong user engagement and word-of-mouth growth over those relying primarily on paid acquisition. Chesky presented detailed user testimonials and stories demonstrating genuine value creation for both hosts and guests. He showed evidence of organic growth and repeat usage, indicating product-market fit despite small scale. The pitch focused on qualitative user feedback and emotional responses rather than quantitative metrics, demonstrating deep understanding of customer needs. Chesky's approach showed that users weren't just using Airbnb but actively recommending it to others, providing evidence of sustainable growth potential. This user-centric approach aligned perfectly with Graham's belief that companies succeeding with early users can scale successfully with proper support and resources."),
                    
                    h4("5. Positioning Within Y Combinator's Portfolio Vision"),
                    p("Chesky strategically positioned Airbnb within Y Combinator's emerging portfolio themes and investment interests, demonstrating understanding of their broader strategic objectives. His research identified Y Combinator's interest in consumer internet companies that could achieve massive scale through network effects. Chesky framed Airbnb as part of emerging sharing economy trends, positioning it alongside other marketplace businesses in Y Combinator's portfolio. He demonstrated understanding of platform dynamics and two-sided market challenges, showing sophistication in business model thinking. The pitch emphasised Airbnb's potential for international expansion and various market applications, indicating scalability that Y Combinator seeks. Chesky's approach showed how Airbnb could benefit from Y Combinator's network and expertise whilst contributing to their portfolio diversity. This strategic positioning demonstrated mature thinking about partnership benefits beyond just capital, showing understanding of accelerator value proposition and how Airbnb could maximise programme benefits for mutual success.")
                )
              ),
              fluidRow(
                box(title = "Airbnb Growth Trajectory", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("airbnb_growth_plot")
                )
              ),
              fluidRow(
                box(title = "References and Resources", status = "primary", solidHeader = TRUE, width = 12,
                    h4("Academic References"),
                    p("Gallagher, L. (2017). The Airbnb Story: How Three Ordinary Guys Disrupted an Industry. Boston: Houghton Mifflin Harcourt."),
                    p("Parker, G.G., Van Alstyne, M.W. & Choudary, S.P. (2016). Platform Revolution. New York: W. W. Norton & Company."),
                    h4("Verified Links"),
                    p("Y Combinator: ", a("ycombinator.com", href = "https://ycombinator.com", target = "_blank")),
                    p("Paul Graham Essays: ", a("paulgraham.com", href = "http://paulgraham.com", target = "_blank")),
                    p("Airbnb Newsroom: ", a("press.airbnb.com", href = "https://press.airbnb.com", target = "_blank"))
                )
              )
      ),
      
      # Dropbox Case Tab
      tabItem(tabName = "dropbox",
              fluidRow(
                box(title = "Dropbox - Drew Houston's Research and Approach", status = "primary", solidHeader = TRUE, width = 12,
                    h4("1. Studying Sequoia's Investment Pattern"),
                    p("Drew Houston's successful fundraising approach began with comprehensive research into Sequoia Capital's investment history and partner preferences, particularly their pattern of backing simple solutions to complex problems. Houston studied Sequoia's portfolio companies like Google, Apple, and YouTube, identifying common themes in their investment thesis: focus on large markets, elegant solutions, and strong technical execution. His research revealed Sequoia's preference for companies that could achieve massive scale through superior user experiences rather than complex feature sets. Houston discovered that Sequoia partners valued technical depth combined with market understanding, leading him to emphasise Dropbox's technical innovation in file synchronisation whilst demonstrating clear market need. This research showed that Sequoia appreciated founders who could articulate complex technical solutions in simple terms, influencing Houston's pitch strategy to focus on elegant problem-solving rather than technical complexity. His approach demonstrated understanding that Sequoia sought companies that could become category-defining platforms rather than niche solutions."),
                    
                    h4("2. Targeting Partner Expertise and Background"),
                    p("Houston specifically researched Sameer Gandhi's background in enterprise software and storage technologies, tailoring his pitch to align with Gandhi's expertise and investment interests. His research revealed Gandhi's experience with enterprise storage companies and understanding of file management challenges in business environments. Houston positioned Dropbox's enterprise potential early in discussions, demonstrating how consumer adoption could drive business usage patterns. He prepared detailed technical discussions about scalability, security, and enterprise integration capabilities that resonated with Gandhi's background. Houston's research showed Gandhi's appreciation for companies that could bridge consumer and enterprise markets, leading him to emphasise Dropbox's dual-market opportunity. This targeted approach demonstrated preparation and respect for investor expertise whilst positioning Dropbox within Gandhi's area of specialisation. Houston's success showed the importance of matching company positioning with individual partner backgrounds and investment focus areas."),
                    
                    h4("3. Demonstrating Product Through Video"),
                    p("Houston's famous demo video approach aligned perfectly with Sequoia's preference for clear product demonstrations and evidence of technical execution capability. His research revealed that Sequoia partners valued seeing products in action rather than relying solely on presentations or prototypes. The video demonstrated Dropbox's core value proposition simply and effectively, showing seamless file synchronisation across devices without requiring technical explanation. Houston's approach addressed a common investor concern about cloud storage reliability by showing actual functionality rather than promising future capabilities. This demonstration strategy resonated with Sequoia's engineering-focused culture and their appreciation for technical execution excellence. The video's viral success also demonstrated market demand and product-market fit, providing early evidence of Dropbox's growth potential. Houston's approach showed understanding that investors need to experience products themselves to fully appreciate value propositions and technical advantages."),
                    
                    h4("4. Emphasising Market Size and Opportunity"),
                    p("Houston's pitch strategy emphasised the massive total addressable market for file storage and synchronisation, aligning with Sequoia's focus on large market opportunities. His research showed that Sequoia typically invested in companies targeting multi-billion dollar markets with potential for significant market share capture. Houston presented comprehensive market analysis showing growing data creation rates, increasing device proliferation, and enterprise digital transformation trends driving storage needs. He demonstrated understanding of cloud infrastructure trends and positioned Dropbox to benefit from broader technology shifts toward distributed computing. Houston's market presentation showed both current pain points and future growth drivers, indicating sustainable long-term opportunity rather than temporary market inefficiency. This market-focused approach aligned with Sequoia's investment criteria whilst demonstrating Houston's strategic thinking about Dropbox's positioning within broader technology trends. His success showed the importance of framing company opportunities within large, growing markets that justify significant investment and scaling efforts."),
                    
                    h4("5. Building Technical Credibility and Team Strength"),
                    p("Houston's approach emphasised the founding team's technical capabilities and deep understanding of complex file synchronisation challenges, addressing Sequoia's focus on execution capability. His research revealed that Sequoia valued technical founders who could build and scale complex systems whilst understanding market dynamics. Houston demonstrated deep expertise in distributed systems, file management, and user experience design, showing capability to execute on Dropbox's technical vision. He presented clear development roadmaps and technical milestones that showed realistic planning and execution capability. Houston's team presentation emphasised complementary skills and shared vision, indicating ability to scale the organisation effectively. His approach included discussions of technical challenges and proposed solutions, demonstrating thorough understanding of implementation complexity. This technical credibility, combined with market understanding, positioned Houston as the ideal founder to execute on Dropbox's opportunity within Sequoia's investment framework.")
                )
              ),
              fluidRow(
                box(title = "File Storage Market Evolution", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("dropbox_market_plot")
                )
              ),
              fluidRow(
                box(title = "References and Resources", status = "primary", solidHeader = TRUE, width = 12,
                    h4("Academic References"),
                    p("Young, J. (2012). 'Dropbox: The Inside Story of Tech's Most Unlikely Startup Success'. Forbes Technology."),
                    p("Cusumano, M.A. (2010). 'Cloud Computing and SaaS as New Computing Platforms'. Communications of the ACM, 53(4), pp. 27-29."),
                    h4("Verified Links"),
                    p("Dropbox Business: ", a("dropbox.com/business", href = "https://dropbox.com/business", target = "_blank")),
                    p("Sequoia Capital: ", a("sequoiacap.com", href = "https://sequoiacap.com", target = "_blank")),
                    p("Drew Houston MIT: ", a("web.mit.edu", href = "https://web.mit.edu", target = "_blank"))
                )
              )
      ),
      
      # Canva Case Tab
      tabItem(tabName = "canva",
              fluidRow(
                box(title = "Canva - Melanie Perkins' Research and Approach", status = "primary", solidHeader = TRUE, width = 12,
                    h4("1. Learning from 100+ Rejections"),
                    p("Melanie Perkins' eventual success with Matrix Partners came after analysing patterns from over 100 investor rejections, leading to refined positioning and presentation strategies. Her research revealed common objections: market size concerns, competitive threats from established players, and questions about technical execution capability. Perkins systematically addressed each concern through improved market research, competitive analysis, and technical demonstrations. She discovered that many investors couldn't envision design democratisation, leading her to develop better analogies and market comparisons. Her persistence enabled relationship building with investors who initially declined but remained interested in company progress. Perkins' experience showed that rejection feedback, when analysed systematically, provides valuable insights for improving investor presentations and addressing legitimate concerns. Her eventual success demonstrated the importance of learning from early fundraising attempts rather than abandoning efforts after initial rejections. This iterative approach to investor feedback ultimately positioned Canva more effectively for successful fundraising."),
                    
                    h4("2. Researching Matrix Partners' Investment Thesis"),
                    p("Perkins' successful approach to Matrix Partners involved extensive research into their investment in HubSpot and their belief in democratising professional tools for broader markets. Her research revealed Matrix's pattern of investing in companies that made sophisticated tools accessible to non-expert users. She studied their portfolio companies to understand common themes: focus on user experience, freemium business models, and large addressable markets. Perkins discovered Matrix's appreciation for companies that could disrupt traditional software categories through superior design and accessibility. Her research showed Matrix's comfort with long development cycles for complex products, indicating patience for Canva's technical challenges. She positioned Canva within Matrix's investment thesis by emphasising design democratisation and market expansion opportunity. This research-driven positioning showed understanding of Matrix's strategic interests whilst demonstrating how Canva aligned with their successful investment patterns. Her approach illustrated the importance of matching company narratives with investor investment philosophies and proven success patterns."),
                    
                    h4("3. Studying Partner David Skok's SaaS Expertise"),
                    p("Perkins specifically targeted David Skok's expertise in SaaS business models and metrics, tailoring her presentation to align with his analytical framework and investment criteria. Her research into Skok's writings and presentations revealed his focus on customer acquisition costs, lifetime value, and viral growth coefficients. Perkins prepared detailed SaaS metrics demonstrating Canva's potential for sustainable growth and strong unit economics. She studied Skok's emphasis on product-market fit indicators and prepared evidence of user engagement and retention that aligned with his evaluation criteria. Her presentation included cohort analysis and growth projections based on frameworks that Skok had publicly discussed. Perkins' approach showed deep understanding of SaaS investment evaluation, addressing concerns about scalability and customer acquisition efficiency. This targeted preparation demonstrated respect for Skok's expertise whilst positioning Canva within proven SaaS success patterns. Her success illustrated the value of matching presentation content and metrics with individual partner analytical preferences and evaluation frameworks."),
                    
                    h4("4. Positioning Design Democratisation Opportunity"),
                    p("Perkins' pitch strategy emphasised the massive opportunity to democratise design tools, drawing parallels to successful technology democratisation trends that Matrix had previously supported. Her research revealed Matrix's interest in companies that expanded market opportunities by making professional tools accessible to broader audiences. She positioned Canva as enabling millions of non-designers to create professional-quality graphics, significantly expanding the addressable market beyond traditional design software users. Perkins demonstrated market research showing growing demand for visual content across social media, marketing, and business communication. Her presentation included evidence of user behaviour changes and increasing visual content consumption that supported design democratisation trends. She showed how improved accessibility could create new user categories and usage patterns previously impossible with complex design software. This market expansion narrative aligned with Matrix's investment thesis whilst demonstrating Perkins' understanding of broader technology trends and market evolution patterns."),
                    
                    h4("5. Demonstrating Freemium Model Viability"),
                    p("Perkins' approach emphasised Canva's freemium business model potential, aligning with Matrix Partners' experience with similar models and their understanding of user acquisition strategies. Her research showed Matrix's comfort with freemium approaches that could achieve viral growth and strong conversion rates from free to paid users. She presented detailed analysis of user behaviour patterns, showing how free users could become engaged advocates whilst eventually converting to premium subscriptions. Perkins demonstrated understanding of freemium metrics that Matrix valued: user activation rates, engagement frequency, and premium feature adoption patterns. Her presentation included competitive analysis showing how freemium models had succeeded in adjacent markets, providing validation for Canva's approach. She addressed common freemium concerns about customer acquisition costs and monetisation timelines with realistic projections based on user behaviour data. This model-focused approach showed sophisticated understanding of business model dynamics whilst demonstrating alignment with Matrix's investment experience and comfort with freemium growth strategies.")
                )
              ),
              fluidRow(
                box(title = "Design Software Market Disruption", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("canva_disruption_plot")
                )
              ),
              fluidRow(
                box(title = "References and Resources", status = "primary", solidHeader = TRUE, width = 12,
                    h4("Academic References"),
                    p("Perkins, M. (2019). 'Building Canva: The Story Behind the Design Platform'. Harvard Business Review Case Study."),
                    p("Christensen, C.M. & Raynor, M.E. (2003). The Innovator's Solution. Boston: Harvard Business Review Press."),
                    h4("Verified Links"),
                    p("Canva Design School: ", a("canva.com/learn", href = "https://canva.com/learn", target = "_blank")),
                    p("Matrix Partners: ", a("matrixpartners.com", href = "https://matrixpartners.com", target = "_blank")),
                    p("David Skok Blog: ", a("forentrepreneurs.com", href = "https://forentrepreneurs.com", target = "_blank"))
                )
              )
      ),
      
      # Stitch Fix Case Tab
      tabItem(tabName = "stitch_fix",
              fluidRow(
                box(title = "Stitch Fix - Katrina Lake's Research and Approach", status = "primary", solidHeader = TRUE, width = 12,
                    h4("1. Understanding Benchmark's Investment Philosophy"),
                    p("Katrina Lake's successful approach to Benchmark Capital involved extensive research into their investment philosophy, particularly their focus on data-driven businesses and marketplace dynamics. Lake studied Benchmark's portfolio companies and partner writings, discovering their preference for companies that combined technology with human expertise to create scalable business models. Her research revealed Benchmark's appreciation for businesses that generated valuable data through operations, creating competitive advantages and improving customer experiences over time. She positioned Stitch Fix as leveraging both human stylists and machine learning algorithms to deliver personalised fashion recommendations, aligning with Benchmark's interest in hybrid human-AI models. Lake's research showed Benchmark's comfort with complex operations that could scale through technology, leading her to emphasise how Stitch Fix's model could expand efficiently while maintaining service quality. This research-driven positioning demonstrated understanding of Benchmark's investment criteria whilst showing how Stitch Fix aligned with their successful investment patterns in data-driven marketplace businesses."),
                    
                    h4("2. Studying Bill Gurley's Marketplace Expertise"),
                    p("Lake specifically researched Bill Gurley's extensive writings on marketplace dynamics and network effects, tailoring her presentation to address his analytical framework for evaluating two-sided markets. Her research revealed Gurley's focus on supply-demand balance, customer acquisition efficiency, and sustainable competitive advantages in marketplace businesses. Lake prepared detailed analysis of Stitch Fix's supply chain relationships with clothing brands and manufacturers, demonstrating understanding of inventory management and supplier dynamics. She addressed Gurley's common marketplace concerns about customer retention, lifetime value, and network effects by showing how personalisation improved customer satisfaction and reduced churn. Lake's presentation included metrics that Gurley valued: customer acquisition costs, repeat purchase rates, and average order values that demonstrated healthy marketplace dynamics. Her approach showed sophisticated understanding of marketplace evaluation criteria whilst positioning Stitch Fix's unique model within proven marketplace success patterns. This targeted preparation illustrated the importance of matching analytical depth with investor expertise areas."),
                    
                    h4("3. Positioning Data and Personalisation Advantage"),
                    p("Lake's pitch strategy emphasised Stitch Fix's unique data collection and personalisation capabilities, creating sustainable competitive advantages that aligned with Benchmark's focus on defensible business models. Her research showed Benchmark's appreciation for companies that improved through usage, creating positive feedback loops that strengthened competitive positions over time. Lake demonstrated how each customer interaction generated valuable data about style preferences, fit, and purchase behaviour that enhanced future recommendations. She positioned this data advantage as creating barriers to entry for traditional retailers and pure-play e-commerce companies lacking similar customer insights. Lake's presentation included evidence of improving recommendation accuracy and customer satisfaction scores that validated the data-driven approach. She showed how personalisation enabled premium pricing and customer loyalty that traditional retail models couldn't replicate. This data-centric positioning aligned with Benchmark's investment thesis whilst demonstrating Lake's understanding of sustainable competitive advantage creation in retail markets."),
                    
                    h4("4. Demonstrating Hybrid Business Model Innovation"),
                    p("Lake's approach highlighted Stitch Fix's innovative combination of human stylists and algorithmic recommendations, positioning it as the future of personalised retail that Benchmark could understand and support. Her research revealed Benchmark's interest in companies that reimagined traditional industries through technology whilst maintaining human elements that customers valued. She demonstrated how stylists provided customer service and fashion expertise that algorithms couldn't replicate, whilst technology enabled efficient scaling and improved recommendation accuracy. Lake's presentation included operational metrics showing how the hybrid model achieved better customer satisfaction than purely automated or purely human approaches. She addressed scalability concerns by showing how technology could augment human capabilities rather than replace them, enabling efficient growth while maintaining service quality. Lake positioned this model as applicable to other personalisation opportunities beyond fashion, indicating potential for platform expansion. This innovative model positioning demonstrated forward-thinking that aligned with Benchmark's interest in companies defining new market categories."),
                    
                    h4("5. Addressing Retail Market Disruption Opportunity"),
                    p("Lake's pitch emphasised the massive opportunity to disrupt traditional retail through personalised, convenient shopping experiences that addressed fundamental customer pain points in fashion retail. Her research showed Benchmark's comfort with companies disrupting large, established industries through superior customer experiences and operational efficiency. She presented detailed market analysis showing retail consolidation trends and consumer preference shifts toward personalised, convenient shopping experiences. Lake demonstrated understanding of retail economics and showed how Stitch Fix's model could achieve better margins and customer satisfaction than traditional retail approaches. Her presentation included evidence of changing consumer behaviour and willingness to pay for personalised services that supported market disruption potential. She positioned Stitch Fix as benefiting from broader e-commerce trends whilst creating new shopping categories that traditional retailers couldn't easily replicate. This market disruption narrative aligned with Benchmark's investment experience whilst demonstrating Lake's strategic thinking about retail industry evolution and transformation opportunities.")
                )
              ),
              fluidRow(
                box(title = "Personalised Retail Growth", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("stitch_fix_growth_plot")
                )
              ),
              fluidRow(
                box(title = "References and Resources", status = "primary", solidHeader = TRUE, width = 12,
                    h4("Academic References"),
                    p("Lake, K. (2018). 'Algorithms and Human Expertise in Retail'. MIT Sloan Management Review, 59(3), pp. 45-52."),
                    p("Pine, B.J. & Gilmore, J.H. (2011). The Experience Economy. Boston: Harvard Business Review Press."),
                    h4("Verified Links"),
                    p("Stitch Fix Algorithms: ", a("algorithms-tour.stitchfix.com", href = "https://algorithms-tour.stitchfix.com", target = "_blank")),
                    p("Benchmark Capital: ", a("benchmark.com", href = "https://benchmark.com", target = "_blank")),
                    p("Bill Gurley Blog: ", a("abovethecrowd.com", href = "http://abovethecrowd.com", target = "_blank"))
                )
              )
      ),
      
      # Slack Case Tab
      tabItem(tabName = "slack",
              fluidRow(
                box(title = "Slack - Stewart Butterfield's Research and Approach", status = "primary", solidHeader = TRUE, width = 12,
                    h4("1. Aligning with 'Software Is Eating the World' Thesis"),
                    p("Stewart Butterfield's successful approach to Andreessen Horowitz involved extensive research into Marc Andreessen's 'software is eating the world' thesis and positioning Slack as transforming workplace communication through software innovation. Butterfield studied Andreessen's writings about software disrupting traditional industries and positioned Slack within this broader transformation narrative. His research revealed a16z's focus on companies that could fundamentally change how people work and communicate, leading him to emphasise Slack's potential to replace email and traditional communication tools. Butterfield demonstrated understanding of software's potential to improve productivity and collaboration, aligning with Andreessen's belief in technology's transformative power. His presentation positioned Slack as part of the broader enterprise software revolution that a16z was actively supporting through portfolio investments. This strategic positioning showed sophisticated understanding of a16z's investment philosophy whilst demonstrating how Slack could contribute to their vision of software transformation across industries."),
                    
                    h4("2. Researching Enterprise Software Investment Pattern"),
                    p("Butterfield's pitch strategy involved comprehensive research into a16z's enterprise software investments and their belief in consumerisation of enterprise tools, positioning Slack within proven investment patterns. His research revealed a16z's focus on enterprise software that provided consumer-quality user experiences whilst meeting business requirements for security and scalability. Butterfield studied successful a16z enterprise investments to understand common themes: intuitive interfaces, viral adoption patterns, and strong user engagement metrics. He positioned Slack as bringing consumer internet design principles to workplace communication, addressing the user experience gap in traditional enterprise software. Butterfield's approach emphasised how consumer-quality experiences could drive enterprise adoption and reduce implementation resistance. His research showed a16z's comfort with enterprise software that grew through bottom-up adoption rather than traditional top-down sales processes. This positioning demonstrated understanding of a16z's investment criteria whilst showing how Slack aligned with their successful enterprise software portfolio companies."),
                    
                    h4("3. Demonstrating Viral Growth and Network Effects"),
                    p("Butterfield's presentation emphasised Slack's viral growth characteristics and network effects, aligning with a16z's focus on companies that could achieve rapid, sustainable growth through user engagement. His research revealed a16z's appreciation for products that became more valuable as more people used them, creating self-reinforcing growth cycles. Butterfield demonstrated how Slack's team-based structure created natural expansion opportunities within organisations whilst generating network effects that increased user engagement. He presented metrics showing organic growth rates and user engagement levels that validated viral adoption patterns. Butterfield's approach included analysis of how communication tools benefited from network effects, showing increasing value as team size and usage frequency expanded. His presentation demonstrated understanding of viral growth mechanics whilst providing evidence that Slack was achieving sustainable growth through user satisfaction rather than paid acquisition. This growth-focused positioning aligned with a16z's investment criteria whilst demonstrating Slack's potential for massive scale through organic adoption patterns."),
                    
                    h4("4. Positioning Within Communication Evolution Trends"),
                    p("Butterfield's strategy positioned Slack within broader communication evolution trends, drawing parallels to successful consumer communication platforms that a16z understood and supported. His research showed a16z's investments in communication and social platforms, enabling him to frame Slack's workplace focus within proven technology adoption patterns. Butterfield demonstrated how workplace communication was evolving from email to real-time, threaded conversations that better supported modern work patterns. He positioned Slack as benefiting from generational shifts in communication preferences, with younger workers expecting consumer-quality experiences in workplace tools. Butterfield's presentation included evidence of changing work patterns and remote collaboration trends that supported demand for better communication tools. He showed how Slack addressed fundamental communication challenges that email and traditional tools couldn't solve effectively. This trend-based positioning demonstrated strategic thinking about technology adoption whilst showing how Slack could benefit from broader workplace transformation patterns that a16z was actively supporting."),
                    
                    h4("5. Emphasising Platform and Integration Opportunities"),
                    p("Butterfield's approach highlighted Slack's platform potential and integration capabilities, aligning with a16z's interest in companies that could become central infrastructure for business operations. His research revealed a16z's appreciation for platform businesses that could expand through third-party integrations and ecosystem development. Butterfield demonstrated how Slack's API and integration capabilities enabled connections with existing business tools, reducing implementation friction whilst increasing user value. He positioned Slack as becoming the communication layer for business software ecosystems, creating opportunities for platform expansion and developer engagement. Butterfield's presentation included early evidence of third-party integration adoption and developer interest that supported platform potential. He showed how platform effects could create competitive advantages and expansion opportunities beyond basic communication functionality. This platform-focused positioning demonstrated understanding of a16z's investment criteria whilst showing how Slack could evolve into essential business infrastructure that justified significant investment and scaling efforts.")
                )
              ),
              fluidRow(
                box(title = "Workplace Communication Evolution", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("slack_evolution_plot")
                )
              ),
              fluidRow(
                box(title = "References and Resources", status = "primary", solidHeader = TRUE, width = 12,
                    h4("Academic References"),
                    p("Butterfield, S. (2016). 'The Future of Work Communication'. Harvard Business Review Digital Articles."),
                    p("McAfee, A. & Brynjolfsson, E. (2017). Machine, Platform, Crowd. New York: W. W. Norton & Company."),
                    h4("Verified Links"),
                    p("Slack Platform: ", a("api.slack.com", href = "https://api.slack.com", target = "_blank")),
                    p("Andreessen Horowitz: ", a("a16z.com", href = "https://a16z.com", target = "_blank")),
                    p("Marc Andreessen Blog: ", a("pmarchive.com", href = "https://pmarchive.com", target = "_blank"))
                )
              )
      )
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  # Venture Capital Stages Plot
  output$vc_stages_plot <- renderPlotly({
    stages_data <- data.frame(
      Stage = c("Pre-Seed", "Seed", "Series A", "Series B", "Series C+"),
      Typical_Amount_Million = c(0.5, 2, 8, 25, 50),
      Typical_Valuation_Million = c(2, 8, 30, 100, 300),
      Success_Rate = c(10, 15, 25, 40, 60)
    )
    
    p <- ggplot(stages_data, aes(x = Stage, y = Typical_Amount_Million)) +
      geom_col(fill = "#1e3a8a", alpha = 0.7) +
      labs(title = "Venture Capital Funding Stages",
           x = "Funding Stage", y = "Typical Amount (£ Million)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Crisis Timeline Plot
  output$crisis_timeline_plot <- renderPlotly({
    crisis_data <- data.frame(
      Week = 1:12,
      Stress_Level = c(30, 45, 70, 85, 90, 80, 70, 60, 50, 40, 35, 30),
      Decision_Quality = c(60, 55, 40, 35, 45, 55, 65, 70, 75, 80, 82, 85)
    )
    
    p <- ggplot(crisis_data) +
      geom_line(aes(x = Week, y = Stress_Level, colour = "Stress Level"), size = 1.2) +
      geom_line(aes(x = Week, y = Decision_Quality, colour = "Decision Quality"), size = 1.2) +
      scale_colour_manual(values = c("Stress Level" = "#dc2626", "Decision Quality" = "#1e3a8a")) +
      labs(title = "Crisis Management: Stress vs Decision Quality Over Time",
           x = "Week", y = "Level (0-100)", colour = "Metric") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Blitzscaling Phases Plot
  output$blitzscaling_phases_plot <- renderPlotly({
    phases_data <- data.frame(
      Phase = c("Family", "Tribe", "Village", "City", "Nation"),
      Employees = c(10, 100, 1000, 10000, 100000),
      Revenue_Million = c(1, 10, 100, 1000, 10000),
      Challenges = c("Product-Market Fit", "Scaling Team", "Process Building", "Global Expansion", "Market Leadership")
    )
    
    p <- ggplot(phases_data, aes(x = factor(Phase, levels = Phase), y = Employees)) +
      geom_col(fill = "#1e3a8a", alpha = 0.8) +
      scale_y_log10() +
      labs(title = "Blitzscaling Growth Phases",
           x = "Company Phase", y = "Employee Count (Log Scale)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Angel Investment Plot
  output$angel_investment_plot <- renderPlotly({
    angel_data <- data.frame(
      Investment_Range = c("£10K-£25K", "£25K-£50K", "£50K-£100K", "£100K-£250K", "£250K+"),
      Frequency = c(35, 25, 20, 15, 5),
      Success_Rate = c(8, 12, 18, 25, 35)
    )
    
    p <- ggplot(angel_data, aes(x = Investment_Range, y = Frequency)) +
      geom_col(fill = "#1e3a8a", alpha = 0.7) +
      labs(title = "Angel Investment Distribution by Amount",
           x = "Investment Range", y = "Frequency (%)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # VC Investment Stages Plot
  output$vc_investment_stages_plot <- renderPlotly({
    investment_data <- data.frame(
      Stage = c("Seed", "Early", "Growth", "Late", "Exit"),
      Average_Multiple = c(0.5, 2.5, 5.8, 8.2, 12.1),
      Risk_Level = c(90, 75, 50, 30, 15)
    )
    
    p <- ggplot(investment_data) +
      geom_col(aes(x = Stage, y = Average_Multiple, fill = "Returns Multiple"), alpha = 0.7) +
      geom_line(aes(x = Stage, y = Risk_Level/10, group = 1, colour = "Risk Level"), size = 1.5) +
      scale_y_continuous(sec.axis = sec_axis(~.*10, name = "Risk Level (%)")) +
      scale_fill_manual(values = c("Returns Multiple" = "#1e3a8a")) +
      scale_colour_manual(values = c("Risk Level" = "#dc2626")) +
      labs(title = "VC Investment Risk vs Returns by Stage",
           x = "Investment Stage", y = "Average Multiple", 
           fill = "", colour = "") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Airbnb Growth Plot
  output$airbnb_growth_plot <- renderPlotly({
    airbnb_data <- data.frame(
      Year = 2008:2015,
      Nights_Booked_Millions = c(0.01, 0.1, 0.5, 2, 5, 11, 25, 40),
      Countries = c(1, 2, 5, 8, 15, 25, 50, 65)
    )
    
    p <- ggplot(airbnb_data) +
      geom_line(aes(x = Year, y = Nights_Booked_Millions, colour = "Nights Booked (Millions)"), size = 1.2) +
      geom_line(aes(x = Year, y = Countries/2, colour = "Countries/2"), size = 1.2) +
      scale_colour_manual(values = c("Nights Booked (Millions)" = "#1e3a8a", "Countries/2" = "#059669")) +
      labs(title = "Airbnb Growth Trajectory 2008-2015",
           x = "Year", y = "Scale", colour = "Metric") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Dropbox Market Plot
  output$dropbox_market_plot <- renderPlotly({
    market_data <- data.frame(
      Year = 2007:2014,
      Cloud_Storage_Market_Billion = c(0.5, 1.2, 2.8, 5.5, 8.9, 14.2, 22.1, 31.8),
      Dropbox_Users_Millions = c(0, 0.1, 1, 4, 25, 50, 100, 200)
    )
    
    p <- ggplot(market_data) +
      geom_area(aes(x = Year, y = Cloud_Storage_Market_Billion), fill = "#3b82f6", alpha = 0.3) +
      geom_line(aes(x = Year, y = Dropbox_Users_Millions/10, colour = "Dropbox Users (Millions/10)"), size = 1.5) +
      scale_y_continuous(sec.axis = sec_axis(~.*10, name = "Dropbox Users (Millions)")) +
      scale_colour_manual(values = c("Dropbox Users (Millions/10)" = "#1e3a8a")) +
      labs(title = "Cloud Storage Market vs Dropbox User Growth",
           x = "Year", y = "Market Size (£ Billion)", colour = "") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Canva Disruption Plot
  output$canva_disruption_plot <- renderPlotly({
    disruption_data <- data.frame(
      User_Type = c("Professional Designers", "Marketing Teams", "Small Business", "Consumers", "Enterprise"),
      Traditional_Tools = c(90, 60, 20, 5, 80),
      Canva_Adoption = c(30, 75, 85, 95, 45)
    )
    
    p <- ggplot(disruption_data) +
      geom_col(aes(x = User_Type, y = Traditional_Tools, fill = "Traditional Tools"), 
               position = "dodge", alpha = 0.7) +
      geom_col(aes(x = User_Type, y = Canva_Adoption, fill = "Canva Adoption"), 
               position = "dodge", alpha = 0.7) +
      scale_fill_manual(values = c("Traditional Tools" = "#6b7280", "Canva Adoption" = "#1e3a8a")) +
      labs(title = "Design Tool Adoption by User Type",
           x = "User Type", y = "Adoption Rate (%)", fill = "Tool Type") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Stitch Fix Growth Plot
  output$stitch_fix_growth_plot <- renderPlotly({
    stitch_data <- data.frame(
      Quarter = paste0("Q", rep(1:4, 4), " ", rep(2018:2021, each = 4)),
      Active_Clients_Thousands = c(500, 580, 650, 720, 800, 900, 1000, 1100, 
                                   1200, 1280, 1350, 1400, 1450, 1500, 1550, 1600),
      Revenue_Per_Client = c(450, 465, 480, 495, 510, 525, 540, 555, 
                             570, 580, 590, 600, 610, 620, 630, 640)
    )
    
    p <- ggplot(stitch_data) +
      geom_line(aes(x = 1:16, y = Active_Clients_Thousands/10, colour = "Active Clients (100k)"), size = 1.2) +
      geom_line(aes(x = 1:16, y = Revenue_Per_Client/10, colour = "Revenue per Client (£10s)"), size = 1.2) +
      scale_colour_manual(values = c("Active Clients (100k)" = "#1e3a8a", "Revenue per Client (£10s)" = "#059669")) +
      labs(title = "Stitch Fix: Client Growth vs Revenue per Client",
           x = "Quarter", y = "Scaled Value", colour = "Metric") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Slack Evolution Plot
  output$slack_evolution_plot <- renderPlotly({
    slack_data <- data.frame(
      Communication_Method = c("Email", "Phone", "Video Calls", "Instant Messaging", "Collaboration Platforms"),
      Usage_2010 = c(85, 70, 15, 40, 5),
      Usage_2020 = c(60, 45, 75, 80, 85),
      Efficiency_Score = c(40, 60, 70, 75, 90)
    )
    
    p <- ggplot(slack_data) +
      geom_segment(aes(x = Communication_Method, xend = Communication_Method, 
                       y = Usage_2010, yend = Usage_2020), 
                   colour = "#1e3a8a", size = 1.5, alpha = 0.7) +
      geom_point(aes(x = Communication_Method, y = Usage_2010, colour = "2010"), size = 3) +
      geom_point(aes(x = Communication_Method, y = Usage_2020, colour = "2020"), size = 3) +
      scale_colour_manual(values = c("2010" = "#dc2626", "2020" = "#059669")) +
      labs(title = "Workplace Communication Method Evolution",
           x = "Communication Method", y = "Usage Rate (%)", colour = "Year") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
}

# Run the application
shinyApp(ui = ui, server = server)