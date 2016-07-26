(function() {

  var ACCESS_TOKEN = '6a93c73f10808b9a92d4ec8a91b9e823c192d204';

  function getMilestone(milestoneNumber) {
    var url = 'https://api.github.com/repos/flutter/flutter/milestones/' +
        milestoneNumber + '?access_token=' + ACCESS_TOKEN;

    return fetch(url).then(function(response) {
      	return response.json();
      });
  }

  function updateLastUpdatedTime() {
    document.querySelector('#github-last-updated-time').textContent = new Date();
  }

  function displayMilestone() {
  	getMilestone(7).then(function(data) {
      function daysBetween(d1, d2) {
        var start = Math.floor( d1.getTime() / (3600*24*1000));
        var end   = Math.floor( d2.getTime() / (3600*24*1000));
        return start - end;
      }

      var card = document.querySelector('#github_issues');
      card.querySelector('.metric-number').textContent = data.open_issues;
      var targetDue = new Date(data.due_on);
      var daysAway = daysBetween(targetDue, new Date());
      card.querySelector('.days-away-number').textContent = daysAway;

      updateLastUpdatedTime();

      setTimeout(displayMilestone, 60*60*1000); // one hour refresh
    });
  }

  displayMilestone();
})();