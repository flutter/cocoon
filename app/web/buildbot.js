// Globally visible list of current build statuses encoded as:
//
// {
//   "Mac": true,
//   "Linux": false
// }
var buildStatuses = {};

function allBuildsGreen() {
  var allGreen = true;
  for (var builderName in buildStatuses) {
    if (buildStatuses.hasOwnProperty(builderName)) {
      allGreen = allGreen && buildStatuses[builderName] === true;
    }
  }
  return allGreen;
}

(function() {
  const url = 'https://build.chromium.org/p/client.flutter/json/builders/';

  function getBuildStatus(builderName) {
    var urlWithBuilder = url + builderName + '/';

    return fetch(urlWithBuilder + 'builds').then(function(response){
      if (response.status !== 200) {
        console.error('Error status listing builds: ' + response.status);
        return Promise.reject(new Error(response.statusText));
      }

      return response.json();
    }).then(function(data) {
      var keys = Object.keys(data);
      var latest = keys[keys.length-1];
      return Promise.resolve(latest);
    }).then(function(latestBuildNum) {
      return Promise.resolve(fetch(urlWithBuilder + 'builds/' + latestBuildNum));
    }).then(function(response) {
      if (response.status !== 200) {
        console.error('Error status retrieving build info: ' + response.status);
        return Promise.reject(new Error(response.statusText));
      }

      return response.json();
    }).then(function(data) {
      var isSuccessful = data['text'] && data['text'][1] === 'successful';
      var elem = document.querySelector('#buildbot-' + builderName.toLowerCase().replace(' ', '-') + '-status');
      buildStatuses[builderName] = isSuccessful;
      if (isSuccessful) {
        elem.classList.remove('buildbot-sad');
        elem.classList.add('buildbot-happy');
      } else {
        elem.classList.remove('buildbot-happy');
        elem.classList.add('buildbot-sad');
      }
    }).catch(function(err) {
      console.error(err);
    });
  }

  function subscribeToDashboardStatus() {
    buildStatuses['dashboard'] = null;
    whenFirebaseReady.then(function(ref) {
      ref.child('measurements').on("value", function(snapshot) {
        var status = snapshot.child('dashboard_bot_status').child('current').val();
        buildStatuses['dashboard'] = (status.success === true);
      }, function (errorObject) {
        console.log("The read failed: " + errorObject.code);
      });
    });
  }

  function refreshAllBuildStatuses() {
    Promise.all([
      getBuildStatus('Linux'),
      getBuildStatus('Linux Engine'),
      getBuildStatus('Mac'),
      getBuildStatus('Mac Engine')
    ]).then(function() {
      var dashboardStatusSpan = document.querySelector('#dashboard-status');
      var dashboardLogLink = document.querySelector('#dashboard-log-link');
      dashboardStatusSpan.classList.remove('buildbot-sad');
      if (allBuildsGreen()) {
        // Show dashboard status green iff it and all other builds are green.
        dashboardLogLink.style.color = '#4CAF50';
      } else if (buildStatuses['dashboard'] === false) {
        // The dashboard is explicitly broken. Go into the broken build mode.
        dashboardLogLink.style.color = 'red';
        dashboardStatusSpan.classList.add('buildbot-sad');
      } else {
        // If one of the buildbots is red the dashboard status is irrelevant.
        // Showing it red won't add any useful information, and showing it green
        // is misleading.
        dashboardLogLink.style.color = '#DDD';
      }

      setTimeout(refreshAllBuildStatuses, 5 * 1000);
    }, function() {
      // Schedule a fetch even if the previous one fails, but wait a little longer
      setTimeout(refreshAllBuildStatuses, 60 * 1000);
    });
  }

  subscribeToDashboardStatus();
  refreshAllBuildStatuses();
})();
