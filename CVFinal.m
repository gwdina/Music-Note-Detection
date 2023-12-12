Raw = imread('MusicSheet.jpg');
Gray = rgb2gray(Raw);
BW = edge(Gray,'canny');
[H, theta, rho] = hough(BW);
peak = houghpeaks(H);
StaffAngle = theta(peak(2));
RotatedCorrected = imrotate_white(Raw, StaffAngle - 90);
%imshow(RotatedCorrected);

Gray = rgb2gray(RotatedCorrected);
BW = Gray > 200;
BW = 1 - BW;
%imshow(BW);



hzst = strel('line', 120, 0);
horz = imerode(BW, hzst);
horz = imdilate(horz, hzst);

vtst = strel('line', 7, 90);
virt = imerode(BW, vtst);
virt = imdilate(virt, vtst);

vtst2 = strel('line', 150, 90);
virt2 = imerode(BW, vtst2);
virt2 = imdilate(virt2, vtst2);

Morphed = BW - horz + virt - virt2 * 2;

imshow(bwareaopen(Morphed, 20));


CC = bwconncomp(Morphed);
S = regionprops(CC);
notes = zeros(numel(S), 4);

for j=1:numel(S)
    if S(j).Area > 50
        rectangle('Position', S(j).BoundingBox, 'EdgeColor', 'r', 'LineWidth', 2);
        notes(j, :) = ceil(S(j).BoundingBox);
    end
end

nonZero = any(notes, 2);
notes = notes(nonZero, :);

disp(notes);

images = cell(numel(S), 1);
cleanImages = cell(numel(S), 1);
for index = 1:size(notes)
    try
        current = (Morphed(notes(index, 2): notes(index, 2) + notes(index, 4), notes(index, 1): notes(index, 1) + notes(index, 3)));
    catch
        current = (Morphed(notes(index, 2): notes(index, 2) + notes(index, 4) - 1, notes(index, 1): notes(index, 1) + notes(index, 3) - 1));
    end
    [labeled, blobs] = bwlabel(current);
    props = regionprops(labeled, 'area');
    [sortedAreas, sortedIndex] = sort([props.Area], 'descend');
    cleanCurrent = ismember(labeled, sortedIndex(1:1));
    cleanImages{index} = current;
    images{index} = cleanCurrent;
end

nonEmptyCells = false(size(images));
for x = 1:numel(images)
    nonEmptyCells(x) = ~isempty(images{x});
end
images = images(nonEmptyCells);
cleanImages = cleanImages(nonEmptyCells);

subplot(1,2,1), montage(images);
subplot(1,2,2), montage(cleanImages);




%Credit to Mustafa Umit Arabul for writing this function to replace
%with white instead of black when rotating
function rotated_image = imrotate_white(image, rot_angle_degree)
    RA = imref2d(size(image));    
    tform = affine2d([cosd(rot_angle_degree)    -sind(rot_angle_degree)     0; ...
                      sind(rot_angle_degree)     cosd(rot_angle_degree)     0; ...
                      0                          0                          1]);
      Rout = images.spatialref.internal.applyGeometricTransformToSpatialRef(RA,tform);
      Rout.ImageSize = RA.ImageSize;
      xTrans = mean(Rout.XWorldLimits) - mean(RA.XWorldLimits);
      yTrans = mean(Rout.YWorldLimits) - mean(RA.YWorldLimits);
      Rout.XWorldLimits = RA.XWorldLimits+xTrans;
      Rout.YWorldLimits = RA.YWorldLimits+yTrans;
      rotated_image = imwarp(image, tform, 'OutputView', Rout, 'interp', 'cubic', 'fillvalues', 255);
  end