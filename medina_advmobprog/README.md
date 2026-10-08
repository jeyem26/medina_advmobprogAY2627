# Medina, John Michael M
## INF - 233 
## CTADMOBL_Advance Mobile Programming 

A flutter Project that focuses on advance topics. Covering the web to mobile transactions

## Lab Activity Instance 

## Lab Activity 1
Dark/Light Mode & State Management: Sa activity na ito, natutunan ko kung paano gumagana ang counter at kung paano nagbabago ang app kapag nag-switch between Light and Dark Mode. Mas naging clear sa akin kung paano ginagamit ang state para ma-update ang UI sa Flutter.

## Lab 2 – Bulldog Exchange 

Sa activity na ito, natutunan ko kung paano gamitin ang Provider pattern sa isang mas advanced na application tulad ng Bulldog Exchange. Natutunan ko rin kung paano gawing consistent ang design ng iba’t ibang parts ng app, gaya ng product cards, navigation, at forms, habang nagpapalit-palit sa Dark at Light Mode. Nakatulong din ito para mas maintindihan ko kung paano maayos na pamahalaan ang theme ng application nang hindi naaapektuhan ang performance nito.

## Lab Activity 3

Sa activity na ito, natutunan ko kung paano gumawa ng Cart Screen at i-connect ito sa API ng Bulldog Exchange. Natutunan ko rin kung paano kumuha ng cart gamit ang user ID, mag-display ng products at quantity, at mag-open ng product details kapag pinindot ang item. Na-implement ko rin ang Add to Cart function at paggamit ng FloatingActionButton para sa chat. Mas naging clear sa akin kung paano kumukuha at nagsesend ng data ang Flutter application sa API.

## Lab Activity 4: 

Sa activity na ito, gumawa ako ng User model at UserService para maayos na makuha at maproseso ang user data mula sa DummyJSON API. Ang UserService ang humahawak sa sign in at pagkuha ng user details, habang ginagamit ng Sign In, Profile, at Cart screens ang result ng service.

Gumagamit ang Sign In screen ng DummyJSON authentication endpoint. Kapag tama ang username at password, sine-save ang user ID, username, email, at access token gamit ang SharedPreferences. Sa pagsisimula ng app, ipinapakita muna ang sariling Splash Screen. Tinitingnan nito ang saved authentication data bago pumunta sa Home screen o Sign In screen.

Sa Profile screen, kinukuha ang saved userId at ginagamit ito sa UserService para makuha ang tunay na user information. Ipinapakita rito ang profile image, pangalan, username, email, gender, at user ID. Sa Cart screen naman, ginagamit ang parehong saved userId sa CartService.getCartsByUserId para ang cart ng naka-sign-in na user ang ma-render, hindi ang cart ng ibang user.

Nagdagdag din ako ng logout function na nag-aalis ng authentication data sa SharedPreferences at bumabalik sa Sign In screen. Sa ganitong paraan, nananatiling signed in ang user kapag isinara at binuksan muli ang app, pero maaari pa ring mag-logout kapag kinakailangan.

## Lab Activity 5: 

for this activity, we enhanced this flutter project application by adding firebase authentication.
We connected firebase to handle the login, logout, password changes, and the account deletion. We also improved the userService so the authenticationn logic is more organized and more easy to manage. So this activity helped us to understand how firebase can be integrated to flutter app




