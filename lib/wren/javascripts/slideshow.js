var c = '#9af';
var prevSlide = function(){
  var slideIndex = $('.slide:visible').index();
  if( slideIndex > 0 ){
    slide( slideIndex-1 );
  }
};

var nextSlide = function(){
  var slideIndex = $('.slide:visible').index();
  if( slideIndex < $('.slide').length-1 ){
    slide( slideIndex+1 );
  }
};

var slide = function(i){
  var thisSlide = $('.slide:visible');
  thisSlide.hide();
  $('.slide-link').css({'background-color':'transparent'});
  
  var nextSlide = $('.slide').slice(i,i+1);
  nextSlide.show();
  $('.slide-link').slice(i,i+1).css({'background-color':c});
};

$('.buttons').append('<a href="#" onclick="prevSlide();return false;">Prev</a> ');
for( var i=0;i<$('.slide').length;i++){
  var link = '<a href="#" class="slide-link" onclick="slide(' + i + ');return false;">' + (i+1) + '</a> ';
  $('.buttons').append(link);
}
$('.buttons').append('<a href="#" onclick="nextSlide();return false;">Next</a> ');

$('.slide').hide();
$('.slide').first().show();
$('.slide-link').first().css({'background-color':c});

