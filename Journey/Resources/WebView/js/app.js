(function() {
  var self = window.Path = {
    templates: {
      feed: $('#feed_template').text()
    , moment: $('#moment_template').text()
    , comments: $('#comments_template').text()
    }

  , refreshing: false

  , init: function() {
      Path.initialized = true;
      Path.killScroll = false;
      Path.loadOldMomentsComplete = false;

      Path.handleWindowScroll();
      Path.handleKeyup();
      //window.setInterval(self.didClickRefreshButton, 15000);
      $('.friend.dot').cycle({fx: 'fade'});
    }

  , renderTemplate: function(name, object, atTop) {
      var $content = $('#content');
      if($content.children('.moments').length == 0) {
        $content.html(_.template(self.templates[name], object));
        $('abbr.timeago').timeago();
        $('.friend.dot').cycle({fx: 'fade'});
        $('#refresh_button').click(self.didClickRefreshButton);
      } else {
        // just prepend moments
        var $newMomentHTML = $(_.map(object.moments, function(m) {
          return _.template(self.templates.moment, {m: m});
        }).join(''));
        $newMomentHTML.find('abbr.timeago').timeago();
        $newMomentHTML.find('.friend.dot').cycle({fx: 'fade'});
        if(atTop) {
          $content.find('.moments').prepend($newMomentHTML);
        } else {
          Path.removeLoadingMessage();
          $content.find('.moments').append($newMomentHTML);
          Path.killScroll = false;
        }
      }
      self.didCompleteRefresh();
    }

  ,didFetchedComments: function(str) {
	  var data = jQuery.parseJSON(str);
	  // now we got comments, and should render them under moments
	  if(!data || !data.comments) {
		  return;
	  }

	  var comments = data.comments;
	  var users = data.users;
	  var locations = data.locations;
	  
	  var $content = $('#content');
	  var momentArea = $content.find('.moments');

	  for(var now in comments) {
		  var moment = momentArea.find('#' + now);
		  var commentArea = moment.find('.comments');
		  var commentInput = null;
		  var commentEls = null;

		  if(commentArea.length > 0) {
			commentEls = commentArea.find('.comment');
			commentEls.remove();
		  } else {
			  moment.append($('<div class="comments-tip"></div><ul class="comments"></ul>'));
			  commentArea = moment.find('.comments');
		  }
		  
		  commentInput = commentArea.find('.comment-create');
		  if(commentInput.length == 0) {
			  //no comment input, create it
			  var inputHtml = "<li class='text comment-create' style='margin-right: 8px;'><input class='comment-input' style='width: 100%;' moment-id='" + now + "'/></li>";
			  commentArea.append($(inputHtml));
		  }
		  commentInput = commentArea.find('.comment-create');

		  var newComments = _.template(self.templates.comments, {m: {comments: comments[now]}});
		  $(newComments).insertBefore(commentInput);

		  //render timeago
		  moment.find("abbr.timeago").timeago();
	  }

	  //TODO all comments deleted and refresh fail cause no moment id
  }

  , didClickRefreshButton: function() {
      if(!self.refreshing) {
        document.location.replace('#refresh_feed');
        self.refreshing = true;
        self.animateRefreshButton(true);
      }
      return false;
    }

  , didCompleteRefresh: function() {
      self.removeHashFragment();
      self.refreshing = false;
      self.animateRefreshButton(false);
    }

  , animateRefreshButton: function(animate) {
      var $imgs = $('#refresh_button img');
      if(animate) {
        $imgs.addClass('loading');
      } else {
        $imgs.removeClass('loading');
      }
    }

  , handleWindowScroll: function() {
      $(window).scroll(function() {
        var scrollTop = $(window).scrollTop();
		var winHeight = $(window).height();

		//load older moments
        if(scrollTop + 200 >= ($(document).height() - winHeight)) {
          if(Path.killScroll === false && Path.loadOldMomentsComplete === false) {
            Path.killScroll = true;
            Path.showLoadingMessage();
            document.location.replace('#load_old_moments');
          }
		//clear unread status
        } else if(scrollTop <= 243) {
          document.location.replace('#clear_status_item_highlight');
        }

		//TODO seen_it

		//refresh comments of seen moments
		var mids = [];
		var firstVisibleFound = false;
		$('#content').find('.moment').each(function(index, moment) {
			if(!moment) {
				//continue
				return true;
			}

			var offset = $(moment).offset();
			if(offset.top > scrollTop && offset.top - scrollTop < winHeight) {
				if(!firstVisibleFound) {
					firstVisibleFound = true;
				}
				mids.push(moment.id);
				//to find next visible
				return true;
			} else {
				if(firstVisibleFound) {
					//stop searching
					var midList = mids.join(',');
					//dunt request every scrolling occur
					if(midList != self.lastScrollItems) {
						document.location.replace('#get_comments?mids=' + midList);
						document.location.replace('#seen_it?mids=' + midList);
					}
					self.lastScrollItems = midList;
					setTimeout(function() {
						//reset it
						if(midList == self.lastScrollItems) {
							self.lastScrollItems = '';
						}
					}, 2000);
					return false;
				} else {
					//keep searching to find first visible moment
					return true;
				}
			}
		});
      });
    }

  , handleKeyup: function() {
	  $(window).keyup(function(e) {
		  var target = $(e.target);

		  //if is comment add
		  if(target.hasClass('comment-input')) {
			//if is enter key, add comment
			if(e.keyCode === 13) {
				var mid = e.target.getAttribute('moment-id');
				var comment = target.val();
				document.location.replace('#create_comment?mid=' + mid + '&comment=' + comment);
				target.val('');
				//TODO append it immediately
			}
		  }
	});
  }
	, log: function(url) {
		self.didClickRefreshButton();
		if(url) {
			var m = $('ul.moments');
			if(m) {
				//m.html('url' + url);
			}
		}
	}

  , showLoadingMessage: function() {
      $('ul.moments').append('<li class="moment fetching"></li>');
    }

  , removeLoadingMessage: function() {
      $('.moments .fetching').remove();
    }

  , removeHashFragment: function() {
      document.location.replace('#_');
    }

  };
}());

