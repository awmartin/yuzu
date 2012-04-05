var currentSlide = 0;

var nextSlide = function(){
  var next = currentSlide+1;
  if( next >= count ) next = 0;
  slide( next );
}

var prevSlide = function(){
  var next = currentSlide-1;
  if( next <= -1 ) next = count-1;
  slide( next );
}

var slide = function(next){
  if( next == currentSlide ) return;
  
  var current_id = "#slide-" + currentSlide;
  var next_id = "#slide-" + next;
  
  $( current_id ).css({'z-index':2});
  $( next_id ).css({'z-index':1});
  
  $( current_id ).fadeOut('slow');
  $( next_id ).fadeIn('slow');
  
  currentSlide = next;
}
